const ethEnabled = async () => {
    if (window.ethereum) {
        window.eth_accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        window.web3 = new Web3(window.ethereum);
        return true;
    }
    return false;
}

ethEnabled().then(enabled => alert("Wallet connected!"));

const nft_address = "0x2184147e89CAFfc711193dcEf406D128e521584a";
const lending_address = "0x79f8b8aceca83850fdac539990e915644079751b";
const ft_address = "0xB4f639B5aFadF00b5e2Be3878e10d765Bec9eeCb";
const api_consumer_address = "0x4Be7C4A3A51D9D87a06D230F441CA7564E685592";



function sendMethodFactory(contract) {
    return function sendMethod(methodName, args, verb = "send", callback) {
        contract.methods[methodName](...args).estimateGas({}, (err, gas) => {
            const result = contract.methods[methodName](...args)[verb]({ gas });
            if (callback) {
                result.then(callback);
            }
        });

    };
}

function nftContract(callback) {
    fetch("abi_nft.json").then(response => response.json()).then(abi => {
        const contract = new web3.eth.Contract(abi, nft_address, { from: window.eth_accounts[0] });
        const sendMethod = sendMethodFactory(contract);
        callback(contract, sendMethod);
    });
}

function lendingContract(callback) {
    fetch("abi_lending.json").then(response => response.json()).then(abi => {
        const contract = new web3.eth.Contract(abi, staking_address, { from: window.eth_accounts[0] });
        const sendMethod = sendMethodFactory(contract);
        callback(contract, sendMethod);
    });
}

function ftContract(callback) {
    fetch("abi_usdc.json").then(response => response.json()).then(abi => {
        const contract = new web3.eth.Contract(abi, ft_address, { from: window.eth_accounts[0] });
        const sendMethod = sendMethodFactory(contract);
        callback(contract, sendMethod);
    });
}

function ftContract(callback) {
    fetch("abi_nft_floor.json").then(response => response.json()).then(abi => {
        const contract = new web3.eth.Contract(abi, ft_address, { from: window.eth_accounts[0] });
        const sendMethod = sendMethodFactory(contract);
        callback(contract, sendMethod);
    });
}



function getErc20Balance(address) {
    ftContract((_, sendMethod) => {
        sendMethod("balanceOf", [address], "call", balance => {
            document.getElementById("usdc_balance").innerHTML = balance;
        });
    });
}

function getErc721Balance(address) {
    nftContract((_, sendMethod) => {
        sendMethod("balanceOf", [address], "call", balance => {
            document.getElementById("nft_balance").innerHTML = balance;
        });
    });
}

function getUsdcPool() {
    stakingContract((_, sendMethod) => {
        sendMethod("get_usdc_pool", [], "call", (numStakers) => {
            document.getElementById("usdc_pool").innerHTML = numStakers;
        });
    });
}

function getNftPool(address) {
    stakingContract((_, sendMethod) => {
        sendMethod("get_total_borrowed", [address], "call", (ids) => {
            let actualIds = ids.filter(id => id != 0);
            document.getElementById("nft_pool").innerHTML = `Count ${actualIds.length}: ${actualIds.join(", ")}`;
        });
    });
}