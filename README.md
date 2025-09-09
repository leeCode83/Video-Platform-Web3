🎥 Video Streaming Platform on Ethereum
Welcome to the Video Streaming Platform—a decentralized application (DApp) built on the Ethereum blockchain. This project showcases a secure and modular architecture for content creators to monetize their video content using an ERC20 token.

Developed with Solidity and the Foundry smart contract development toolkit, this platform provides a robust framework for managing video content and payments in a trustless environment.

🌟 Project Highlights
Decentralized Monetization: Content creators can upload videos and set their own viewing fees, earning income directly from viewers.

Modular Architecture: The system is designed with a clear separation of concerns across three main contracts, enhancing security and maintainability.

Gas-Efficient Transactions: By handling payments as internal balance updates within a single contract, we significantly reduce the number of on-chain token transfers, saving gas costs for users.

Secure & Auditable: Built with industry-standard libraries like OpenZeppelin and protected against common vulnerabilities like reentrancy attacks.

Foundry-Powered: The entire project leverages the power of the Foundry toolchain for a fast, efficient, and reliable development workflow.

📝 Core Components
Our platform's functionality is driven by three interconnected smart contracts:

VideoPlatformFactory.sol 🏭
This is the heart of the platform, responsible for deploying new video contracts. It maintains a registry of all active videos and their corresponding creators, acting as the central entry point for the system.

VideoPlatformPayment.sol 💰
This contract serves as the secure financial hub. All user deposits and payments are managed here. When a viewer pays a fee, the contract simply updates the internal balances, moving tokens from the viewer's balance to the creator's. Users can withdraw their funds from this contract at any time.

Video.sol 🎞️
Each instance of this contract represents a single video. It holds key metadata such as the video's URI and its viewing fee. Its primary function is to interact with the VideoPlatformPayment contract to process the viewing fee when a user watches the video.

🚀 How It Works
The platform operates on a simple, transparent, and secure flow:

Deposit: A user deposits ERC20 tokens into the VideoPlatformPayment contract.

Create: A creator pays a small ETH fee to the VideoPlatformFactory to create a new Video contract with their specified viewing fee and video URI.

Watch & Pay: When a viewer calls the watchVideo function on a Video contract, it triggers an updateDeposit call to the VideoPlatformPayment contract.

Balance Update: The VideoPlatformPayment contract deducts the fee from the viewer's internal balance and credits it to the creator's balance. No actual token transfer occurs at this step, which is a major gas saver.

Withdraw: The creator can withdraw their accumulated earnings from the VideoPlatformPayment contract whenever they choose.

This structure ensures that the platform is robust, scalable, and easy to maintain, while providing a seamless experience for both creators and viewers.