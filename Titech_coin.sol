pragma solidity ^0.4.16;

import "./SafeMath.sol";

contract Titech_coin {

     using SafeMath for uint256;  //uint256変数にはSafeMathを適用する。

    //ネットワーク上にリリースするトークン名とティッカー
     string public constant symbol = "TTC";
     string public constant name = "Titech Coin";

     //総供給量と対ethレートの定義
     uint256 _totalSupply = 1000000; //1000 x 100 (小数点以下分を含む)
     uint256 _currentSupply = 0;
     uint256 public constant RATE = 1000; //1TTL = 0.1eth
     uint256 public constant decimals = 2;
     //0.0001まで存在できる。
     address public owner;

     // オーナーとユーザーの関係を定義してマッピング
     mapping(address => uint256) balances;
     mapping(address => mapping (address => uint256)) allowed;  //流通のため、オーナーから払い出したトークンの取り扱いをユーザーに許可する。
     modifier onlyOwner() {
         require(msg.sender == owner);
         _;
     }

     modifier onlyPayloadSize(uint256 size){
         assert(msg.data.length >= size + 4);
         _;
     }

     //トークンのフォールバック関数
     function() payable{
         createTokens(msg.sender);
     }

     // 以下動作部分となるコンストラクタ、自分のアドレスでハードコードした。
     function Titech_coin() {
         owner = 0xbFF8F08EF46F629B90f5752986AF7e7c4aa196c7;
         balances[owner] = _totalSupply;
     }

    // コインはownerだけが自分のアカウントに追加できるになっている。
    function mint(uint _value) public {
      require(msg.sender == owner);
      mintToken(_value);
    }

    function mintToken(uint _value) internal {
      balances[owner] += _value;
      _totalSupply += _value;
      require(balances[owner] >= _value && _totalSupply >= _value);
      emit Transfer(owner, owner, _value);
    }

    //ownerのみ実行可能であり、ownerの口座に調達したetherを送金するう。
    function withdraw() public onlyOwner(){
      owner.transfer((this).balance);
    }

    //ethとttcの交換処理
    function createTokens(address addr) payable{
        require(msg.value > 0);
        uint256 tokens = msg.value.mul(RATE).div(1 ether);
        require(_currentSupply.add(tokens) <= _totalSupply);
        balances[owner] = balances[owner].sub(tokens);
        balances[addr] = balances[addr].add(tokens);
        Transfer(owner, addr, tokens);

        owner.transfer(msg.value);
        _currentSupply = _currentSupply.add(tokens);
    }
    //交換処理後にオーナーのトークン総数をリフレッシュ
    function totalSupply()  constant returns (uint256 totalSupply) {
         return _totalSupply;
     }

     //アカウントにあるトークン数の表示
     function balanceOf(address _owner) constant returns (uint256 balance) {
         return balances[_owner];
     }

     // 交換したTTLの送付
     function transfer(address _to, uint256 _value) returns (bool success) {
         require(
             balances[msg.sender] >= _value
             && _value > 0
             );
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
     }

     // TTL獲得後の流通のための関数
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         require(
             balances[_from] >= _value
             && allowed[_from][msg.sender] >= _value
             && _value > 0
        );
             balances[_from] = balances[_from].sub(_value);
             allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
             balances[_to] = balances[_to].add(_value);
             Transfer(_from, _to, _value);
             return true;
    }

     // 発行元から入手した保有者に流通権限を与える（それ以外の流通を許可しない安全策）
     function approve(address _spender, uint256 _value) returns (bool success) {
         allowed[msg.sender][_spender] = _value;
         Approval(msg.sender, _spender, _value);
      return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
