# Deployment (this fork)

Build: GitHub Actions · target host: `bj.20100212.xyz` · port: `32346` · image: `ghcr.io/xueyuanpang-google/phira-mp`

## 1. Build pipeline

`.github/workflows/build.yml` runs on every push to `main` (and manually via *workflow_dispatch*) and:

1. compiles `phira-mp-server` for `x86_64-unknown-linux-musl` → **static** binary;
2. packages a `tar.gz` and a `.deb` (systemd unit included, listens on 32346);
3. builds and pushes a Docker image to GHCR:
   * `ghcr.io/xueyuanpang-google/phira-mp:latest`
   * `:build-<run_number>`, `:sha-<short sha>`
4. publishes a GitHub release `build-<run_number>` with the tarball + deb.

### Baseline-CPU constraint (important)

The deployment host is a QEMU VM with CPU model `QEMU Virtual CPU version 2.5+` (kvm64): **no AVX/AVX2**.
Any binary containing AVX in code that runs before feature detection dies with `SIGILL` (exit 132).

Therefore the workflow pins baseline code generation:

```yaml
RUSTFLAGS: "-C target-cpu=x86-64"
CFLAGS:    "-mno-avx -mno-avx2 -mno-avx512f -mno-fma -mno-avx512vl"
CXXFLAGS:  "-mno-avx -mno-avx2 -mno-avx512f -mno-fma -mno-avx512vl"
```

The `CFLAGS` part matters because `aws-lc-sys` (rustls' crypto backend, pulled in by `reqwest`)
compiles its C with AVX otherwise, which breaks `aws_lc_*_OPENSSL_cpuid_setup` — the CPU probe
itself — on non-AVX CPUs. The `Reject non-baseline CPU instructions` step fails the build if
AVX ever reappears inside CPU-detection code.

## 2. Run with Docker (current deployment)

```bash
docker login ghcr.io -u <user>          # only if the package is private
mkdir -p /opt/phira-mp
# compose file: docker/compose.yaml
cd /opt/phira-mp && docker compose up -d
```

`docker/compose.yaml` publishes `32346:32346`, sets `restart: unless-stopped`, and keeps logs in
the named volume `phira-mp-logs`.

### Host firewall

1Panel's firewall chain (`1PANEL_BASIC` → `1PANEL_BASIC_AFTER -j DROP`) drops everything not
explicitly allowed, so 32346 must be allowed:

```bash
iptables -I 1PANEL_BASIC 1 -p tcp -m tcp --dport 32346 -j ACCEPT
```

`phira-mp-fw-guard.service` + `.timer` (installed on the host) re-assert this rule after boot and
every 2 minutes, in case the panel regenerates its chains.

## 3. DNS

| record | value |
| --- | --- |
| `phira.20100212.xyz` | `CNAME` → `bj.20100212.xyz` (DNS only, dynamic A record via ddns-go) |
| `_phira._tcp.phira.20100212.xyz` | `SRV 10 5 32346 phira.20100212.xyz` |

Clients that support SRV lookup (`_phira._tcp.<host>`) only need `phira.20100212.xyz`;
otherwise use `bj.20100212.xyz:32346`.

## 4. Alternative: install the .deb

```bash
sudo dpkg -i phira-mp_<version>_amd64.deb   # creates user phira-mp, enables phira-mp.service
systemctl status phira-mp
```

The unit runs as `phira-mp`, works in `/var/lib/phira-mp`, and is sandboxed with
`ProtectSystem=strict`.
