# clipboard-utils

Small clipboard helpers with a **configurable backend**.

The main command is **`co`**: it copies stdin to the configured clipboard.
The helper commands copy common terminal values into `co`.

## Purpose

The default use-case is local and simple:

```bash
printf hello | co
cowd
cof file
cob value
coc file
cor command
```

By default, `co` copies to the **local machine clipboard** using the first
available backend: `wl-copy`, `xclip`, then `xsel`.

The remote use-case is hclip. One machine is the **receiver**: the main
computer with the GUI and the real clipboard. Other machines are **senders**:
SSH sessions, servers, containers, VMs, or console-only environments. Senders
run the same commands, but their clipboard payloads land on the receiver's
actual clipboard.

## Install

Choose a directory where you keep local tools, for example:

```bash
mkdir -p ~/tools
cd ~/tools
```

Then clone the repo and run the installer on every machine where you want to
run `co` commands:

```bash
git clone https://github.com/hruskamiro/clipboard-utils.git
cd clipboard-utils
./install.sh
```

Keep the checkout in place because the installer creates symlinks to it.

This creates command symlinks in `~/.local/bin` and config at:

```text
~/.config/clipboard-utils/config
```

It also installs **tab completion for Bash** into the user completion directory.

Check without changing anything:

```bash
./install.sh check
```

Uninstall managed symlinks:

```bash
./install.sh uninstall
```

## Default Local Use

```bash
printf hello | co
co config show

cowd               # copy current working directory
cof path ...       # copy absolute path values, one per line
cob value ...      # copy bare argument values, one per line
coc file           # copy file content
coc -f file        # same as coc --full: include hostname, time, path, size, and lines
cor command        # run command, print stdout+stderr, and copy it
cor -f command     # same as cor --full: include hostname, time, pwd, command, and status
```

Choose a local backend explicitly if needed:

```bash
co config backend local
co config backend xclip
co config backend wl-copy
co config backend xsel
```

## Remote Use: Encrypted SSH Transport

For remote use, **prefer SSH transport**. hclip listens only on the receiver's
localhost, and SSH forwards a local port from the sender to the receiver.

### Receiver

The receiver is the main computer with the GUI clipboard.

```bash
hclip-secret generate
hclip-start --bind 127.0.0.1
co remote export --ssh-select hclip-remote.conf
```

To specify a particular receiver SSH address instead of choosing interactively:

```bash
co remote export --ssh user@receiver-host hclip-remote.conf
```

Move `hclip-remote.conf` to the sender.

### Sender

The sender is the remote machine, SSH session, server, VM, or container.

```bash
co remote import hclip-remote.conf
hclip-tunnel print-command
hclip-tunnel start
hclip-tunnel status
printf hello | co
```

In SSH mode, the sender's `co` config points to `127.0.0.1:23143`.
`hclip-tunnel start` opens the SSH tunnel to the receiver.
`hclip-tunnel stop` closes the managed tunnel.

### Sender Tunnel Service

To keep the sender's SSH tunnel running with user-level systemd:

```bash
hclip-tunnel-service check
hclip-tunnel-service install
hclip-tunnel-service enable
hclip-tunnel-service start
hclip-tunnel-service status
```

The sender tunnel service requires non-interactive SSH authentication. Key-based
auth without prompts is the simplest option. If your key needs an agent or
hardware prompt, run `hclip-tunnel-service check` before enabling the service.

Other service commands:

```bash
hclip-tunnel-service stop
hclip-tunnel-service restart
hclip-tunnel-service disable
hclip-tunnel-service uninstall
```

### Receiver Service

To run the receiver on login with user-level systemd:

```bash
hclip-secret generate
hclip-service install --bind 127.0.0.1
hclip-service enable
hclip-service start
hclip-service status
```

Custom port:

```bash
hclip-service install --bind 127.0.0.1 23144
hclip-service restart
```

## Remote Use: Unencrypted Direct Transport

**Warning:** direct hclip transport is not encrypted. Use it only on a trusted
network or VPN. The receiver defaults to localhost; direct transport requires
binding to a LAN address explicitly.

There are two addresses to choose:

- **Bind address**: where the receiver listens.
- **Export address**: what senders connect to.

Receiver, bound to one LAN address:

```bash
hclip-secret generate
hclip-start --bind 192.168.1.20
co remote export 192.168.1.20 hclip-remote.conf
```

To listen on all interfaces, bind explicitly to `0.0.0.0` but still export the
specific address senders should use:

```bash
hclip-start --bind 0.0.0.0
co remote export 192.168.1.20 hclip-remote.conf
```

Or choose the export address interactively:

```bash
co remote export --host-select hclip-remote.conf
```

Sender:

```bash
co remote import hclip-remote.conf
printf hello | co
```

Use a non-default port:

```bash
hclip-start --bind 192.168.1.20 23144
co remote export 192.168.1.20 23144 hclip-remote.conf
```

If the export address is omitted, `co remote export` chooses one from
**`HCLIP_EXPORT_HOST`**, then local `HCLIP_HOST`, then the **default-route
source address**. It does not prompt interactively; pass the address explicitly
when interface choice matters.

## hclip Maintenance

Rotate the receiver secret when old exported configs should stop working:

```bash
hclip-secret rotate
co remote export --ssh-select hclip-remote.conf
```

Manual receiver commands:

```bash
hclip-start
hclip-status
hclip-stop
hclip-secret path
```

hclip runtime state lives in:

```text
${XDG_STATE_HOME:-~/.local/state}/clipboard-utils/hclip
```

Override it with `HCLIP_STATE_DIR`.

## Config Reference

Manual hclip sender config:

```bash
co config hclip receiver-host 23143 receiver-secret
```

The config file uses shell-style values:

```bash
CLIPBOARD_BACKEND=local
HCLIP_HOST=
HCLIP_PORT=23143
HCLIP_SECRET=
```

The default config path is `~/.config/clipboard-utils/config`.
Environment variables override config values.

## License

MIT. See [LICENSE](LICENSE).
