echo "===== Cleaning the configtx ======"
rm ./five-org/*.tx  2> /dev/null
rm ./five-org/*.block 2> /dev/null
rm -rf ./five-org/crypto-config 2> /dev/null
rm -rf ./five-org/temp


echo "Done."
