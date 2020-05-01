set -ex
mkdir aquachain-miner # should not exist
# clean everything
cleanall(){
  make clean
  make -C aquahash clean
  make -C spdlog clean
}
cleanall

# build each, copy to folder and clean afterwards
make -j4 config=plain spdlog/libspdlog.a
make -j4 config=plain
mv bin/* aquachain-miner/
cleanall
make -j4 config=avx spdlog/libspdlog.a
make -j4 config=avx
mv bin/* aquachain-miner/
cleanall
make -j4 config=avx2 spdlog/libspdlog.a
make -j4 config=avx2
mv bin/* aquachain-miner/
cleanall

tar czvf aquachain-miner-linux-amd64.tar.gz aquachain-miner/
ls -thalr aquachain-miner-linux-amd64.tar.gz
file aquachain-miner-linux-amd64.tar.gz
sha256sum aquachain-miner-linux-amd64.tar.gz
