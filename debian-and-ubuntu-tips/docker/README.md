DockerのコンテナエンジンはDockerとその互換エンジンであるPodmanがある。

互換性があるため大きな違いはないが、Dockerが開発しているDockerは比較的ホームユース寄りで、Red Hatが開発しているPodmanは比較的エンタープライズユース寄りである。

- Podmanの利点：
  - rootlessはセキュリティーが高いが、Podmanはデフォルトでrootlessであり、rootlessで使う場合にインストールが簡単
  - Quadletによって、Dockerのような独自の仕組みではなくsystemdサービスとしてコンテナを常時起動させられる
  - Kubernetesと類似性が高い
  - Singularityコンテナを実行できる
  - Docker Composeを使うこともできる
- Dockerの利点：
  - Docker Composeによって簡便な方法でコンテナを常時起動させられる
  - Swarm ModeによってKubernetesに比べてシンプルにクラスター化できる

近年はホームユースでもPodmanが使われることが多い。Swarm Modeを使わないのであればPodmanのほうが利点が多いと思われる。

- 参考：
  - [Why are you using podman instead of docker? : r/podman](https://www.reddit.com/r/podman/comments/1eu5d2k/why_are_you_using_podman_instead_of_docker/)
  - [docker or k8s? : r/selfhosted](https://www.reddit.com/r/selfhosted/comments/1dowhi3/docker_or_k8s/)
- 参考になりそうな本
  - [Podmanイン・アクション](https://www.amazon.co.jp/dp/4798070203)
  - [systemdの思想と機能](https://www.amazon.co.jp/dp/429713893X)