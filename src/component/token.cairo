#[starknet::component]
pub mod token_component{
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StoragePathEntry};

    #[storage]
    struct Storage{
        owner: ContractAddress,
        pub name:felt252,
        pub symbol:felt252,
        pub decimal:u8,
        pub supply:u256,
        pub balance: Map::<ContractAddress, u256>,
        pub allowance: Map::<(ContractAddress,ContractAddress),u256>
    }

    #[event]
    #[derive(Drop, starknet::Event, Debug, PartialEq)]
    pub enum Event {
        Transfer:Transfer,
        Allowance:Allowance
    }

    #[derive(Drop, starknet::Event, Debug, PartialEq)]
    pub struct Transfer{
        #[key]
        pub from:ContractAddress,
        #[key]
        pub to:ContractAddress,
        #[key]
        pub amount:u256
    }

    #[derive(Drop, starknet::Event, Debug, PartialEq)]
    pub struct Allowance{
        #[key]
        pub owner:ContractAddress,
        #[key]
        pub spender:ContractAddress,
        #[key]
        pub amount:u256
    }
    
    #[embeddable_as(token)]
    impl TokenImpl<TContractState, +HasComponent<TContractState>> of Token::interfaces::token::IERC20<ComponentState<TContractState>> {

        fn get_name(self: @ComponentState<TContractState>) -> felt252{
            self.name.read()
        }
        fn get_symbol(self: @ComponentState<TContractState>) -> felt252{
            self.symbol.read()
        }
        fn get_decimal(self: @ComponentState<TContractState>) -> u8{
            self.decimal.read()
        }

        fn allowance(self:@ComponentState<TContractState>, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowance.entry((owner, spender)).read()
        }        

        fn balance_of(self:@ComponentState<TContractState>, address: ContractAddress) -> u256 {
            self.balance.entry(address).read()
        }

        fn get_total_supply(self: @ComponentState<TContractState>) -> u256 {
            self.supply.read()
        }

        fn approve(ref self:ComponentState<TContractState>, amount: u256, to: ContractAddress){
            let current = self.allowance.entry((get_caller_address(),to)).read();
            assert(self.balance.entry(get_caller_address()).read() >= current + amount, 'Not enough money in bank');
            self.allowance.entry((get_caller_address(),to)).write(current + amount);
            self.emit(Allowance{owner:get_caller_address(),spender:to,amount:amount});
        }

        fn transferFrom(ref self:ComponentState<TContractState>, from: ContractAddress, amount: u256, to: ContractAddress){
            assert(self.balance.entry(from).read() >= amount, 'Not enough money in bank');
            let current = self.allowance.entry((get_caller_address(),to)).read();
            assert(current >= amount, 'Not allowed');
            self.allowance.entry((get_caller_address(),to)).write(current - amount);
            self._transfer(from,amount,to);
        }

        fn transfer(ref self:ComponentState<TContractState>, amount: u256, to: ContractAddress){
            assert(self.balance.entry(get_caller_address()).read() >= amount, 'Not enough money in bank');
            self._transfer(get_caller_address(),amount,to);
        }   
    }

    #[generate_trait]
    pub impl ERC20Private<TContractState, +HasComponent<TContractState>> of PrivateTrait<TContractState> {
        fn _transfer(ref self:ComponentState<TContractState>, from:ContractAddress, amount: u256, to: ContractAddress){
            let currentFrom:u256 = self.balance.entry(from).read();
            let currentTo:u256 = self.balance.entry(to).read();
            self.balance.entry(from).write(currentFrom - amount);
            self.balance.entry(to).write(currentTo + amount);
            self.emit(Transfer{from:from,to:to,amount:amount});
        }

        fn _init(ref self: ComponentState<TContractState>, owner: ContractAddress, name:felt252, symbol:felt252, decimal:u8, initial_supply:u256) {
            self.name.write(name);
            self.symbol.write(symbol);
            self.decimal.write(decimal);
            self.supply.write(initial_supply);
            self.balance.entry(owner).write(initial_supply);
            self.owner.write(owner);
        }
    }
}