pragma solidity ^0.4.25;

contract EthereumMarket {

    // 変数の宣言
    address owner; //　コントラクトオーナーのアドレス
    uint public numItems; // 商品数
    bool public stopped; // trueの場合Circuit Breakerが発動し、全てのコントラクトが使用不可能になる

    // ?CS? スマコンに何らかの不具合が発生した際に使用する非常停止機能


    // コンストラクタではコントラクトをデプロイしたEthアドレスをownerに保存し、numItemsとstoppedを初期化している
    constructor() public {
        owner = msg.sender; // コントラクトをデプロイしたアドレスをオーナーに指定する
        numItems = 0;
        stopped = false;
    }

    // 呼び出しがコントラクトのオーナーか確認するmodifier　onlyOwnerはオーナーだけが実行可能な関数の修飾子
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // 呼び出しがアカウント登録ずみのEthアドレスか確認するmodifier
    modifier onlyUser {
        require(accounts[msg.sender].registered);
        _;
    }

    // アカウント情報を保持するためのデータ構造体
    struct account {
        string name; 
        string email;
        uint numTransactions; // 取引回数
        int reputations; // 取引評価、大きい値ほど良いアカウント
        bool registered; // アカウント未登録:false,登録ずみ:true
        int numSell; // 出品した商品の数
        int numBuy; // 購入した商品の数
    }
    // 各アカウントのEthアドレスをkeyとして、各情報を記録する
    mapping(address => account) public accounts;

    // 各アカウントが出品、購入した商品番号
    // 本来は各アカウントが出品、購入した商品番号はaccountのメンバにするべきだが、
    // solidityの構造体には配列をメンバにすることができないため、
    // 新たにこれらを記録するデータ構造体を宣言する。
    mapping(address => uint[])public sellItems;
    mapping(address => uint[])public buyItems;
    // 出品や購入をしたEthアドレスの配列に商品番号が追加される。


    // アカウント情報を登録する関数（registerAccount）
    // 引数にアカウント名_nameとEmailアドレス_emailを指定。
    // 初めに、未登録のEthアドレスからの呼び出しか確認する。
    // その後、registerAccountを呼び出したEthアドレスをkeyとしてaccountsに情報を記録する。
    function registerAccount(string _name, string _email)public isStopped {
        require(!accounts[msg.sender].registered); //未登録のEthアドレスか確認

        accounts[msg.sender].registered = true;
        accounts[msg.sender].name = _name; //名前
        accounts[msg.sender].email = _email; //emailアドレス
    }
    

    // 商品情報を記録するためのデータ構造体
    struct item {
        address sellerAddr; //出品者のEthアドレス
        address buyerAddr; //購入者のEthアドレス
        string seller; //出品者名
        string name; //商品名
        string description; //商品説明
        uint price; // 価格（単位:wei）
        bool payment; //false:未支払い、true:支払い済み
        bool shipment; //false:未発送、true:発送済み
        bool receivement; //false:未受け取り、true:受け取り済み
        bool sellerReputate; //出品者の評価完了ステート、false:未評価、true:評価済み
        bool buyerReputate; //購入者の評価完了ステート、false:未評価、true:評価済み
        bool stopSell; //false:出品中、true:出品取り消し
    }
    // keyは商品番号（符号なし整数）　各商品に対して記録する
    mapping(uint => item) public items;

    //商品画像の在処
    struct image{
        string googleDocID; 
        string ipfsHash;
    }
    mapping(uint => image) public images;


    //出品する関数
    function sell(string _name, string _description, uint _price, string _googleDocID, string _ipfsHash) public onlyUser isStopped {
        items[numItems].sellerAddr = msg.sender; //出品者のEthアドレス
        items[numItems].seller = accounts[msg.sender].name; //出品者名
        items[numItems].name = _name; //商品名
        items[numItems].description = _description; //商品説明
        items[numItems].price = _price;
        images[numItems].googleDocID = _googleDocID;
        images[numItems].ipfsHash = _ipfsHash;
        // msg.senderはコントラクトを実行したアドレス
        accounts[msg.sender].numSell++; //各アカウントが出品した商品数の更新
        sellItems[msg.sender].push(numItems); //各アカウントが出品した商品の番号を記録
        numItems++; //出品されている商品数を1つ増やす
    }

    // 購入する関数。修飾子payableを付与。代金は購入者が受け取り通知をするまでフリマアプリが預かる
    // フリマアプリが正しく動作するためには、関数が実行されるタイミングを制御することが重要になる。
    // すでに購入ずみの商品を別のユーザーが購入できてはいけない。二重支払いとなる。
    function buy(uint _numItems) public payable onlyUser isStopped{
        require(!items[_numItems].payment); //商品が売り切れていないか確認
        require(!items[_numItems].stopSell); //出品取り消しになっていないか確認
        require(items[_numItems].price == msg.value); // 入金金額が商品価格と一致しているか確認
    
    
        items[_numItems].payment = true;         // 支払済みにする
        items[_numItems].stopSell = true;        // 売れたので出品をストップする
	    items[_numItems].buyerAddr = msg.sender; // 購入者のEthアドレスを登録する
        accounts[msg.sender].numBuy++;           // 各アカウントが購入した商品数の更新
        buyItems[msg.sender].push(_numItems);    // 各アカウントが購入した商品の番号を記録
    }
    
    

    // 発送完了を通知する関数
    function ship(uint _numItems)public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender); //呼び出しが出品者か確認
        require(items[_numItems].payment); //入金済み商品か確認
        require(!items[_numItems].shipment); //未発送の商品か確認

        //上記3つを満たした場合のみ、発送ステートを発送済みに変更する
        items[_numItems].shipment = true; //発送済みにする
    }


    //受取完了を通知し、出品者へ代金を送金する関数
    function receive(uint _numItems)public payable onlyUser isStopped {
        require(items[_numItems].buyerAddr == msg.sender); //呼び出しが購入者か確認
        require(items[_numItems].shipment); //発送済み商品か確認
        require(!items[_numItems].receivement); //受け取り前の商品か確認

        items[_numItems].receivement = true; //受取済みにする

        //受け取りが完了したら出品者に代金を送金する
        items[_numItems].sellerAddr.transfer(items[_numItems].price);
    }


    //　購入者が出品者を評価する関数
    function sellerEvaluate(uint _numItems, int _reputate) public onlyUser isStopped {
        require(items[_numItems].buyerAddr == msg.sender); //呼び出しが購入者か確認
        require(items[_numItems].receivement); //商品の受け取りが完了していることを確認
        require(_reputate >= -2 && _reputate <= 2); //評価は−2　〜　+2の範囲で行う
        require(!items[_numItems].sellerReputate); //出品者の評価が完了をしていないことを確認

        items[_numItems].sellerReputate = true; //評価済みにする
        accounts[items[_numItems].sellerAddr].numTransactions++; //出品者の取引回数の加算
        accounts[items[_numItems].sellerAddr].reputations += _reputate; //出品者の評価の更新
    }


    // 出品者が購入者を評価する関数
    function buyerEvaluate(uint _numItems, int _reputate)public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(items[_numItems].receivement);
        require(_reputate >= -2 && _reputate <= 2);
        require(!items[_numItems].buyerReputate);

        items[_numItems].buyerReputate = true;
        accounts[items[_numItems].buyerAddr].numTransactions++;
        accounts[items[_numItems].buyerAddr].reputations += _reputate;
    }


    // ===============================
    // 例外処理を行うためのステートと関数
    // ===============================

    //アカウント情報を修正する関数
    function modifyAccount(string _name, string _email) public onlyUser isStopped {
        accounts[msg.sender].name = _name;
        accounts[msg.sender].email = _email;
    }

    //出品内容を変更する関数
    function modifyItem(uint _numItems, string _name, string _description, uint _price, string _googleDocID, string _IPFSHash)public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender); 
        require(!items[_numItems].payment);
        require(!items[_numItems].stopSell);

        items[_numItems].seller = accounts[msg.sender].name;
        items[_numItems].name = _name;
        items[_numItems].description = _description;
        items[_numItems].price = _price;
        images[_numItems].googleDocID = _googleDocID;
        images[_numItems].ipfsHash = _IPFSHash;
    }

    //出品を取り消す関数（出品者）
    function sellerStop(uint _numItems)public onlyUser isStopped {
        require(items[_numItems].sellerAddr == msg.sender);
        require(!items[_numItems].stopSell);
        require(!items[_numItems].payment);

        items[_numItems].stopSell = true; //出品の取り消し
    }

    //出品を取り消す関数（オーナー）
    function ownerStop(uint _numItems) public onlyOwner isStopped {
        require(!items[_numItems].stopSell); //出品中の商品か確認
        require(!items[_numItems].payment); //購入されていない商品か確認

        items[_numItems].stopSell = true; // 出品の取り消し
    }
    //返金する際に参照するステート
    mapping(uint => bool)public refundFlags; //返金するとfalseからtrueに変わる

    //購入者へ返金する関数（出品者）
    function refundFromSeller(uint _numItems)public payable onlyUser isStopped {
        require(msg.sender == items[_numItems].sellerAddr); //呼び出しが出品者か確認
        require(items[_numItems].payment); //支払い済み商品か確認
        require(!items[_numItems].receivement); //出品者が代金を受け取る前か確認
        require(!refundFlags[_numItems]); //すでに返金された商品ではないか確認

        refundFlags[_numItems] = true; //返金済みにする
        items[_numItems].buyerAddr.transfer(items[_numItems].price); //購入者へ返金
    }

    //購入者へ返金する関数（オーナー）
    function refundFromOwner(uint _numItems)public payable onlyOwner isStopped {
        require(items[_numItems].payment);
        require(!items[_numItems].receivement);
        require(!refundFlags[_numItems]);

        refundFlags[_numItems] = true; //返金済みにする
        items[_numItems].buyerAddr.transfer(items[_numItems].price); 
    }


    // ===============================
    // 例外処理を行うためのステートと関数
    // ===============================

    // Circuit Breakerの実装
    // isStoppedはCSが発動している時に処理を実行しないmodifier
    modifier isStopped {
        require(!stopped);
        _;
    }

    //Cirduit Breakerを発動、停止する関数(toggleCircuit)
    //スマコンは一度デプロイしてしまうと修正できないため、何らかの不具合が生じた時のために
    //CSを実装しておく。
    function toggleCircuit(bool _stopped)public onlyOwner {
        stopped = _stopped;
    }

    //Mortal(コントラクトを破壊する機能)の実装
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }


}
