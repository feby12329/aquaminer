set -ex
mkdir aquachain-miner # should not exist
# clean everything
cleanall(){
  make clean
  make -C aquahash clean
  make -C spdlog clean
}

# build each, copy to folder and clean afterwards
cleanall
make -j4 config=plain deps default
mv bin/* aquachain-miner/
cleanall
make -j4 config=avx deps default
mv bin/* aquachain-miner/
cleanall
make -j4 config=avx2 deps default
mv bin/* aquachain-miner/
cleanall

tar czvf aquachain-miner-linux-amd64.tar.gz aquachain-miner/
ls -thalr aquachain-miner-linux-amd64.tar.gz
file aquachain-miner-linux-amd64.tar.gz
sha256sum aquachain-miner-linux-amd64.tar.gz
