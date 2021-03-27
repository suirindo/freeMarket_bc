pragma solidity ^0.4.25:

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
        require(accounts[msg.sender].resistered);
        _;
    }

    // アカウント情報を保持するためのデータ構造体
    struct account {
        stiring name; 
        string email;
        uint numTransactions; // 取引回数
        int reputations; // 取引評価、大きい値ほど良いアカウント
        bool resistered; // アカウント未登録:false,登録ずみ:true
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
    mapping(address => uint[])public buyItemss;
    // 出品や購入をしたEthアドレスの配列に商品番号が追加される。


    // アカウント情報を登録する関数（registerAccount）
    // 引数にアカウント名_nameとEmailアドレス_emailを指定。
    // 初めに、未登録のEthアドレスからの呼び出しか確認する。
    // その後、registerAccountを呼び出したEthアドレスをkeyとしてaccountsに情報を記録する。
    function registerAccount(string_name, string_email)public isStopped {
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
        string descriptions; //商品説明
        uint price; // 価格（単位:wei）
        bool payment; //false:未支払い、true:支払い済み
        bool shipment; //false:未発送、true:発送済み
        bool receivement; //false:未受け取り、true:受け取り済み
        bool sellerReputate; //出品者の評価完了ステート、false:未評価、true:評価済み
        bool buyerReputate: //購入者の評価完了ステート、false:未評価、true:評価済み
        bool stopSell; //false:出品中、true:出品取り消し
    }
    // keyは商品番号（符号なし整数）　各商品に対して記録する
    mapping(uint => item) public items;

    //商品画像の在処
    struct image{
        string googleDocID; 
        string ipfsHash;
    }
    mapping(uint => image) public image;


    //出品する関数
    function sell(stirng_name, string_description, uint_price, string_googleDocID, string_ipfsHash) public onlyUser isStopped {
        items[numItems].sellerAddr = msg.sender; //出品者のEthアドレス
        items[numItems].seller = accounts[msg.sender].name; //出品者名
        items[numItems].name = _name; //商品名
        items[numItems].description = _description; //商品説明
        items[numItems].price = _price;
        images[numItems].googleDocID = _googleDocId;
        images[numItems].ipfsHash = _ipfsHash;
        // msg.senderはコントラクトを実行したアドレス
        accounts[msg.sender].numSell++; //各アカウントが出品した商品数の更新
        sellItems[msg.sender].push(numItems); //各アカウントが出品した商品の番号を記録
        numItems++: //出品されている商品数を1つ増やす
    }

    // 購入する関数。修飾子payableを付与。代金は購入者が受け取り通知をするまでフリマアプリが預かる
    // フリマアプリが正しく動作するためには、関数が実行されるタイミングを制御することが重要になる。
    // すでに購入ずみの商品を別のユーザーが購入できてはいけない。二重支払いとなる。
    function buy(uint _numItems) public payable onlyUser isStopped{
        require(!items[_numItems].payment); //商品が売り切れていないか確認
        require(!items[_numItems].stopSell); //出品取り消しになっていないか確認
        require(!items[_numItems].price == msg.value); // 入金金額が商品価格と一致しているか確認

　　　　　//他のユーザーが購入できないようにする
        items[_numItems].payment = true; //支払い済みにする
        items[_numItems].stopSell = true; //売れたので出品をストップする
        items[_numItems].buyerAddr = msg.sender; //購入者のEthアドレスを登録する
        accounts[msg.sender].numBuy++; //各アカウントが購入した商品数の更新
        buyItems[msg.sender].push(_numItems); //各アカウントが購入した商品の番号を記録
    }














}
