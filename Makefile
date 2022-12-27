
BUILD=./build
.PHONY: artifacts, deploy

artifacts: 
	mkdir -p artifacts
	cp ${BUILD}/BioAsset.sol/BioAsset.json artifacts/bioasset.json
	cp ${BUILD}/BioToken.sol/BioToken.json artifacts/biotoken.json
	cp ${BUILD}/Factory.sol/Factory.json artifacts/factory.json
	cp ${BUILD}/NoFeeMarket.sol/NoFeeMarket.json artifacts/nofeemarket.json

deploy:
	forge script script/Bionet.s.sol:BionetScript --fork-url http://0.0.0.0:8545 --broadcast
