#[starknet::contract]
pub mod MockERC20{
    use starknet::{ContractAddress};
    use token::components::token::token_component;

    component!(path: token_component, storage: token, event: ERC20Event);

    #[abi(embed_v0)]
    impl TokenImpl = token_component::ERC20<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        token: token_component::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event, Debug, PartialEq)]
    pub enum Event {
        ERC20Event: token_component::Event,
    }

    impl TokenPrivate = token_component::TokenPrivate<ContractState>;

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, name:felt252, symbol:felt252, decimal:u8, initial_supply:u256) {
        self.token._init(owner, name, symbol, decimal, initial_supply);
    }
}