name := fedora

.PHONY: install
install: install-repos install-packages install-flatpak-packages install-graphics install-media

.PHONY: install-repos
install-repos:
	$(info [$(name)] Installing RPM Fusion repos...)
	@sudo dnf install -y -q \
		https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm \
		https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm

.PHONY: install-packages
install-packages:
	$(info [$(name)] Installing packages...)
	@sudo dnf install -y -q \
		bat \
		ca-certificates \
		curl \
		difftastic \
		dnf5-plugins \
		dos2unix \
		fd-find \
		fedora-workstation-repositories \
		firefox \
		flatpak \
		gifsicle \
		git \
		git-delta \
		gtk-layer-shell \
		hexyl \
		htop \
		iftop \
		java-25-openjdk-devel \
		jq \
		keepassxc \
		maven \
		ncdu \
		net-snmp-utils \
		ngrep \
		pdftk \
		python3-devel \
		python3-pip \
		python3-virtualenv \
		python3.12 \
		qbittorrent \
		ripgrep \
		simple-scan \
		ttyd \
		unzip \
		unrar \
		wtype \
		wl-clipboard \
		yt-dlp

.PHONY: install-flatpak-packages
install-flatpak-packages:
	$(info [$(name)] Installing Flatpak packages...)
	@flatpak install flathub \
		com.spotify.Client

.PHONY: install-graphics
install-graphics:
	$(info [$(name)] Installing graphics drivers...)
	@sudo dnf install -y -q \
		mesa-dri-drivers \
		mesa-vulkan-drivers \
		libva-utils
	@if lspci -nn | grep -qi 'intel.*vga\|vga.*intel'; then \
		echo "[$(name)] Intel GPU detected — installing intel-media-driver..."; \
		sudo dnf install -y -q intel-media-driver; \
	fi
	@if lspci -nn | grep -qi 'amd.*vga\|vga.*amd\|advanced micro devices.*vga\|vga.*advanced micro devices'; then \
		echo "[$(name)] AMD GPU detected — installing udev perf rule..."; \
		printf 'ACTION=="add", SUBSYSTEM=="drm", DRIVERS=="amdgpu", ATTR{device/power_dpm_force_performance_level}="high"\n' \
			| sudo tee /etc/udev/rules.d/30-amdgpu-perf.rules > /dev/null; \
	fi

.PHONY: install-media
install-media:
	$(info [$(name)] Installing media codecs...)
	@sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
	@sudo dnf group upgrade -y multimedia \
		--setopt="install_weak_deps=False" \
		--exclude=PackageKit-gstreamer-plugin
	@sudo dnf install -y -q \
		lame \
		openh264 \
		pipewire-codec-aptx \
		x264 \
		x265
