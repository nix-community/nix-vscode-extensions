{
	description = "Nix VSCode Marketplace";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, mach-nix, flake-utils }:
	flake-utils.lib.eachDefaultSystem (system: let
		pkgs = nixpkgs.legacyPackages.${system};
	in {
		packages = with pkgs.vscode-utils; {
			ms-python.python = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-python";
					name = "python";
					version = "2022.11.11881005";
					sha256 = "1gsixshag5ir03qsai9869bhrvxwm48brp1d8rajmh80c9lzzlgh";
				};
			};
			ms-toolsai.jupyter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-toolsai";
					name = "jupyter";
					version = "2022.7.1001902022";
					sha256 = "0dbjghvx5faxkf12sm285hid4i1q0d421bfvpaif9ax8a3nlvil2";
				};
			};
			ms-python.vscode-pylance = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-python";
					name = "vscode-pylance";
					version = "2022.7.21";
					sha256 = "1m2x6kb7965fisrca24padl3152adxns2rrzkn6wkm9gai9ms7kw";
				};
			};
			ms-vscode.cpptools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "cpptools";
					version = "1.11.0";
					sha256 = "0ccbh3f00dcb7ldmahxi4kcmbixjjjpb2mp3bic749i98sna9fpv";
				};
			};
			ritwickdey.LiveServer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ritwickdey";
					name = "LiveServer";
					version = "5.7.5";
					sha256 = "0afjp8jr1s0f3ag0q8kw5d8cyd5fh6vzkfx2wdqq4pihm7ivp9xc";
				};
			};
			ms-toolsai.jupyter-keymap = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-toolsai";
					name = "jupyter-keymap";
					version = "1.0.0";
					sha256 = "0wkwllghadil9hk6zamh9brhgn539yhz6dlr97bzf9szyd36dzv8";
				};
			};
			esbenp.prettier-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "esbenp";
					name = "prettier-vscode";
					version = "9.5.0";
					sha256 = "0h5g746ij36h22v1y2883bqaphds7h1ck8mg8bywn9r723mxdy1g";
				};
			};
			ms-toolsai.jupyter-renderers = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-toolsai";
					name = "jupyter-renderers";
					version = "1.0.8";
					sha256 = "0cci7lr947mzxdx4cf9l6v5diy4lnlr32zzg2svs41zfdmarbdni";
				};
			};
			dbaeumer.vscode-eslint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dbaeumer";
					name = "vscode-eslint";
					version = "2.2.6";
					sha256 = "0m16wi8slyj09r1y5qin9xsw4pyhfk3mj6rs5ghydfnppb45w9np";
				};
			};
			VisualStudioExptTeam.vscodeintellicode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "VisualStudioExptTeam";
					name = "vscodeintellicode";
					version = "1.2.22";
					sha256 = "1svgrdx5p0j81k9lyn8y77rsg9c1l2i7ywwml9wrr54cbl0ynl1a";
				};
			};
			MS-CEINTL.vscode-language-pack-zh-hans = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-zh-hans";
					version = "1.69.7060951";
					sha256 = "15gwdz1z8bdl73y5bfmhvw3cmjlxzhzbx9lis12pvcdrxrngb3fj";
				};
			};
			redhat.java = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "java";
					version = "1.9.2022070705";
					sha256 = "003wgq89aacmrw52zlb04rwm1yc612q2i3sadrwd81lp33vszxfr";
				};
			};
			ms-dotnettools.csharp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-dotnettools";
					name = "csharp";
					version = "1.25.0";
					sha256 = "1cqqjg8q6v56b19aabs9w1kxly457mpm0akbn5mis9nd1mrdmydl";
				};
			};
			ms-azuretools.vscode-docker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-docker";
					version = "1.22.0";
					sha256 = "12qfwfqaa6nxm6gg2g7g4m001lh57bbhhbpyawxqk81qnjw3vipr";
				};
			};
			eamodio.gitlens = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eamodio";
					name = "gitlens";
					version = "12.1.1";
					sha256 = "0i1wxgc61rrf11zff0481dg9s2lmv1ngpwx8nb2ygf6lh0axr7cj";
				};
			};
			ms-vscode-remote.remote-wsl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-wsl";
					version = "0.66.3";
					sha256 = "0lslahxz5c6qxlv7xrq6da1x8ry297c4hgx0cb3iln6brj93j20a";
				};
			};
			vscjava.vscode-java-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-java-debug";
					version = "0.42.2022062902";
					sha256 = "1am210xjxki3kmzjb6jnid6dxr3j0l9fv6l57523xjvs0va0pzx3";
				};
			};
			vscjava.vscode-maven = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-maven";
					version = "0.36.2022070703";
					sha256 = "0nsx48ybd0d9drgkg390511vx103dvli368g3pi62la0khhv1y8d";
				};
			};
			vscjava.vscode-java-test = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-java-test";
					version = "0.35.2022070202";
					sha256 = "13052my478kfnai0bmyvd4nrdrqrxai2hl3jpk85m5iwn0kz9vgf";
				};
			};
			ms-vscode-remote.remote-containers = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-containers";
					version = "0.241.2";
					sha256 = "1rwna8wmv46i8y1kvd8gyzghknagjb1hgiqn2q1nwy93hgd2c3d7";
				};
			};
			vscjava.vscode-java-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-java-pack";
					version = "0.24.2022063000";
					sha256 = "1c1yx0m6225ivmxmmpw2mzf9np52zxnd2i7a4cc2mk0mcshw0c9b";
				};
			};
			formulahendry.code-runner = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "code-runner";
					version = "0.11.8";
					sha256 = "1h95zpl7sr4kdjwymyk5ambxa5gmzpnyj63ixyjiy6kffh9s872x";
				};
			};
			vscjava.vscode-java-dependency = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-java-dependency";
					version = "0.20.2022070700";
					sha256 = "1wsbc4c8al0y0bfpvzcah9c0v3zibrqmnlf0ilszd70vg7jip0wg";
				};
			};
			PKief.material-icon-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "PKief";
					name = "material-icon-theme";
					version = "4.19.0";
					sha256 = "1azkkp4bnd7n8v0m4325hfrr6p6ikid88xbxaanypji25pnyq5a4";
				};
			};
			ms-vscode-remote.remote-ssh = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-ssh";
					version = "0.83.2022070715";
					sha256 = "09qsxzmjp2zmglhs7ha4gs1lhgadl4ix0l97n00yyipmnpkyf471";
				};
			};
			vscode-icons-team.vscode-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscode-icons-team";
					name = "vscode-icons";
					version = "11.12.0";
					sha256 = "121177jwcy73xp1cx8v1kcm5w63pqsa1ydhqwwnjdhazm6dkl9wg";
				};
			};
			octref.vetur = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "octref";
					name = "vetur";
					version = "0.35.0";
					sha256 = "1l1w83yix8ya7si2g3w64mczh0m992c0cp2q0262qp3y0gspnm2j";
				};
			};
			ms-vscode-remote.remote-ssh-edit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-ssh-edit";
					version = "0.80.0";
					sha256 = "0zgrd2909xpr3416cji0ha3yl6gl2ry2f38bvx4lsjfmgik0ic6s";
				};
			};
			ecmel.vscode-html-css = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ecmel";
					name = "vscode-html-css";
					version = "1.13.0";
					sha256 = "161jrc8pdvwqb74804rf8m5bpbnd9wyz2f7zn1zch5sw3jgg7mz7";
				};
			};
			twxs.cmake = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "twxs";
					name = "cmake";
					version = "0.0.17";
					sha256 = "11hzjd0gxkq37689rrr2aszxng5l9fwpgs9nnglq3zhfa1msyn08";
				};
			};
			ms-vscode.cmake-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "cmake-tools";
					version = "1.12.12";
					sha256 = "0kqnk3bmiqr921jlqvhrrrr0lf5bf7i9dfam2hhxjn2pxih3a6wb";
				};
			};
			formulahendry.auto-rename-tag = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "auto-rename-tag";
					version = "0.1.10";
					sha256 = "0nyilwfs2kbf8v3v9njx1s7ppdp1472yhimiaja0c3v7piwrcymr";
				};
			};
			msjsdiag.debugger-for-chrome = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "msjsdiag";
					name = "debugger-for-chrome";
					version = "4.13.0";
					sha256 = "0r6l804dyinqfk012bmaynv73f07kgnvvxf74nc83pw61vvk5jk9";
				};
			};
			MS-vsliveshare.vsliveshare = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-vsliveshare";
					name = "vsliveshare";
					version = "1.0.5641";
					sha256 = "0vr2crlcc0gg4z9hbpjnjap9ly5h4fvp744f4zwr0nxb3y83pvvm";
				};
			};
			HookyQR.beautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HookyQR";
					name = "beautify";
					version = "1.5.0";
					sha256 = "1c0kfavdwgwham92xrh0gnyxkrl9qlkpv39l1yhrldn8vd10fj5i";
				};
			};
			xabikos.JavaScriptSnippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xabikos";
					name = "JavaScriptSnippets";
					version = "1.8.0";
					sha256 = "19xg24alxsvq8pvafprshg7qxzx8p37bzk7qz6kjgkpvandrdpl6";
				};
			};
			redhat.vscode-yaml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-yaml";
					version = "1.8.0";
					sha256 = "1djd4mxnfrrlgiyrqjrrchza3q229sy57d71dggvf6f5k2wnj1qv";
				};
			};
			jeff-hykin.better-cpp-syntax = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jeff-hykin";
					name = "better-cpp-syntax";
					version = "1.15.19";
					sha256 = "13v1lqqfvgkf5nm89b39hci65fnz4j89ngkg9p103l1p1fhncr41";
				};
			};
			abusaidm.html-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "abusaidm";
					name = "html-snippets";
					version = "0.2.1";
					sha256 = "1ryqwyhgbwiqxqdh08bfplylkhvcfx17n6l9dyf0xf7fraa3b6ws";
				};
			};
			ms-vscode.cpptools-themes = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "cpptools-themes";
					version = "1.0.0";
					sha256 = "0nds0bx9zsnfgfqgpzlbd79wwnjnhsivf0qbnbiakhj2z8c0niqk";
				};
			};
			cschlosser.doxdocgen = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cschlosser";
					name = "doxdocgen";
					version = "1.4.0";
					sha256 = "1d95znf2vsdzv9jqiigh9zm62dp4m9jz3qcfaxn0n0pvalbiyw92";
				};
			};
			CoenraadS.bracket-pair-colorizer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "CoenraadS";
					name = "bracket-pair-colorizer";
					version = "1.0.62";
					sha256 = "0zck9kzajfx0jl85mfaz4l92x8m1rkwq2vlz0w91kr2wq8im62lb";
				};
			};
			ms-vscode.cpptools-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "cpptools-extension-pack";
					version = "1.2.0";
					sha256 = "155id1ln4nd14a5myw0b5qil4zprcwwplaxw8z7s6z24k7jqni9h";
				};
			};
			formulahendry.auto-close-tag = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "auto-close-tag";
					version = "0.5.14";
					sha256 = "1k4ld30fyslj89bvjh2ihwgycb0i11mn266misccbjqkci5hg1jx";
				};
			};
			christian-kohler.path-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "christian-kohler";
					name = "path-intellisense";
					version = "2.8.1";
					sha256 = "1j7q4mzj173sl6xl3zjw40hnqvyqsrsczakmv63066k4k0rb6clm";
				};
			};
			golang.Go = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "golang";
					name = "Go";
					version = "0.34.1";
					sha256 = "0q0xgmv7g77rnx8mzvaws5lh6za98h9hks06yhyzbc98ylba3gff";
				};
			};
			xdebug.php-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xdebug";
					name = "php-debug";
					version = "1.27.0";
					sha256 = "10grbzxxzhl6nbh967qjsm3zny1m39xa33d9dwrn1r8p22wrffdc";
				};
			};
			GitHub.vscode-pull-request-github = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitHub";
					name = "vscode-pull-request-github";
					version = "0.47.2022070709";
					sha256 = "1g12pqdyddd3n1dhz9mdzidpi84idms90fkv4s9x2s87fs8xb06l";
				};
			};
			bmewburn.vscode-intelephense-client = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bmewburn";
					name = "vscode-intelephense-client";
					version = "1.8.2";
					sha256 = "1sla3pl3jfdawjmscwf2ml42xhwjaa9ywdgdpl6v99p10w6rvx9s";
				};
			};
			donjayamanne.githistory = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "githistory";
					version = "0.6.19";
					sha256 = "15s2mva9hg2pw499g890v3jycncdps2dmmrmrkj3rns8fkhjn8b3";
				};
			};
			ms-vscode.PowerShell = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "PowerShell";
					version = "2022.6.3";
					sha256 = "01hx0gr9h26w287888lffwz7pr9ccbdjms2s50j21pskda91mj9z";
				};
			};
			techer.open-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "techer";
					name = "open-in-browser";
					version = "2.0.0";
					sha256 = "1s5mgw0jaasis0ish3da3dl7vqsgkx9cgrp1mmpgh9c4wlr12xnx";
				};
			};
			felixfbecker.php-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "felixfbecker";
					name = "php-intellisense";
					version = "2.3.14";
					sha256 = "19jw0yh7gir8mr9hpglg5gcdhag1wdbh0z9mfww81dbj27gab61p";
				};
			};
			writenothing.no-code = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "writenothing";
					name = "no-code";
					version = "2.0.2";
					sha256 = "0rr5n8j0papwy54vcrx9l0n7fkhz0rc5l8yfr7nh34ndwmvhsvzh";
				};
			};
			zhuangtongfa.Material-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "zhuangtongfa";
					name = "Material-theme";
					version = "3.15.2";
					sha256 = "058md25509l9nlgicab59rv13alyksbnf6gm55b8yhkbxx6pm079";
				};
			};
			dsznajder.es7-react-js-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dsznajder";
					name = "es7-react-js-snippets";
					version = "4.4.3";
					sha256 = "1xyhysvsf718vp2b36y1p02b6hy1y2nvv80chjnqcm3gk387jps0";
				};
			};
			EditorConfig.EditorConfig = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "EditorConfig";
					name = "EditorConfig";
					version = "0.16.4";
					sha256 = "0fa4h9hk1xq6j3zfxvf483sbb4bd17fjl5cdm3rll7z9kaigdqwg";
				};
			};
			eg2.vscode-npm-script = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eg2";
					name = "vscode-npm-script";
					version = "0.3.28";
					sha256 = "0wf5zn2mkvmyasli6nhqr5rpnmpv1aw7pqa6b2k3fw254by8ys35";
				};
			};
			CoenraadS.bracket-pair-colorizer-2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "CoenraadS";
					name = "bracket-pair-colorizer-2";
					version = "0.2.4";
					sha256 = "1vdd3l5khxacwsqnzd9a19h2i7xpp3hi7awgdfbwvvr8w5v8vkmk";
				};
			};
			ms-mssql.mssql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-mssql";
					name = "mssql";
					version = "1.15.0";
					sha256 = "1al8vbxwxmi5zjalyr720sm3n2kqi8m49s684yqrams9v7mjaij4";
				};
			};
			Dart-Code.dart-code = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Dart-Code";
					name = "dart-code";
					version = "3.44.0";
					sha256 = "1w96362zx4r2972a1c1m9qapv8viaqjd6dy7dlfpvlgmr30s1bma";
				};
			};
			Zignd.html-css-class-completion = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Zignd";
					name = "html-css-class-completion";
					version = "1.20.0";
					sha256 = "1hc2dgib3wryygb36h47wzf32iv1x6rn1swmbgchiyjw62jjj4fw";
				};
			};
			streetsidesoftware.code-spell-checker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "streetsidesoftware";
					name = "code-spell-checker";
					version = "2.2.5";
					sha256 = "0ayhlzh3b2mcdx6mdj00y4qxvv6mirfpnp8q5zvidm6sv3vwlcj0";
				};
			};
			tht13.python = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tht13";
					name = "python";
					version = "0.2.3";
					sha256 = "1b2adxkx8akwh4638cf41lzyyr0b6qp6knirfa9y26dy7k0gf1w8";
				};
			};
			Dart-Code.flutter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Dart-Code";
					name = "flutter";
					version = "3.44.0";
					sha256 = "18dfvnrmz7y3lr3s3y1pxaldqa9ynqzb1qjxdp9jxki6q3v8zyxw";
				};
			};
			christian-kohler.npm-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "christian-kohler";
					name = "npm-intellisense";
					version = "1.4.2";
					sha256 = "0bkgc9fkfpk2mnmr4f7f7c458i1cniy940s5nxap029ysnp6c0yw";
				};
			};
			yzhang.markdown-all-in-one = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yzhang";
					name = "markdown-all-in-one";
					version = "3.4.3";
					sha256 = "0z0sdb5vmx1waln5k9fk6s6lj1pzpcm3hwm4xc47jz62iq8930m3";
				};
			};
			GitHub.github-vscode-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitHub";
					name = "github-vscode-theme";
					version = "6.0.0";
					sha256 = "1vakkwnw43my74j7yjp30kfmmbc37jmr3qia5lvg8sbws3fq40jj";
				};
			};
			austin.code-gnu-global = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "austin";
					name = "code-gnu-global";
					version = "0.2.2";
					sha256 = "1fz89m6ja25aif6wszg9h2fh5vajk6bj3lp1mh0l2b04nw2mzhd5";
				};
			};
			batisteo.vscode-django = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "batisteo";
					name = "vscode-django";
					version = "1.10.0";
					sha256 = "03kr0y7qgsbvp0kcxqlnhqai85g9pdxxys6f36ijvrj6m3f88dmx";
				};
			};
			MS-CEINTL.vscode-language-pack-ja = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-ja";
					version = "1.69.7061001";
					sha256 = "17qzg3p41k4z65lbdnpzl1mj1ajifqp7qi1rf1dvq32fajqm20xi";
				};
			};
			naumovs.color-highlight = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "naumovs";
					name = "color-highlight";
					version = "2.6.0";
					sha256 = "1ssh5d4kn3b57gfw5w99pp3xybdk2xif8z6l7m3y2qf204wd1hsd";
				};
			};
			dracula-theme.theme-dracula = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dracula-theme";
					name = "theme-dracula";
					version = "2.24.2";
					sha256 = "1bsq00h30x60rxhqfdmadps5p1vpbl2kkwgkk6yqs475ic89dnk0";
				};
			};
			TabNine.tabnine-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "TabNine";
					name = "tabnine-vscode";
					version = "3.6.1";
					sha256 = "1kv5v53ysnkp7jnl9zk8n828bgdfrbmqy69xxdv3cc647yzpw0h7";
				};
			};
			wholroyd.jinja = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wholroyd";
					name = "jinja";
					version = "0.0.8";
					sha256 = "1ln9gly5bb7nvbziilnay4q448h9npdh7sd9xy277122h0qawkci";
				};
			};
			vscodevim.vim = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscodevim";
					name = "vim";
					version = "1.23.1";
					sha256 = "131fnicsknw4kkz299l9mdq1b0lx05ssr8sszk1apgmxxngzfz4k";
				};
			};
			MS-vsliveshare.vsliveshare-audio = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-vsliveshare";
					name = "vsliveshare-audio";
					version = "0.1.91";
					sha256 = "0p00bgn2wmzy9c615h3l3is6yf5cka84il5331z0rkfv2lzh6r7n";
				};
			};
			DavidAnson.vscode-markdownlint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DavidAnson";
					name = "vscode-markdownlint";
					version = "0.47.0";
					sha256 = "0v50qcfs3jx0m2wqg4qbhw065qzdi57xrzcwnhcpjhg1raiwkl1a";
				};
			};
			ms-vscode.azure-account = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "azure-account";
					version = "0.11.0";
					sha256 = "02qkpirsvr2m1b18vnzmxqcx77ccr5d38s3wg6lvdndv00niyry3";
				};
			};
			DotJoshJohnson.xml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DotJoshJohnson";
					name = "xml";
					version = "2.5.1";
					sha256 = "1v4x6yhzny1f8f4jzm4g7vqmqg5bqchyx4n25mkgvw2xp6yls037";
				};
			};
			Angular.ng-template = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Angular";
					name = "ng-template";
					version = "14.0.1";
					sha256 = "0a1k0yz4b6ivwwyl4sv9fpr4g91hpndz1s7pa9pg6bfy6njn5d4x";
				};
			};
			kiteco.kite = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kiteco";
					name = "kite";
					version = "0.147.0";
					sha256 = "0dwpmkwxk810mah26cxilm3qzslh0lrwinpqn0ykjvzl6xm1dssb";
				};
			};
			oderwat.indent-rainbow = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oderwat";
					name = "indent-rainbow";
					version = "8.3.1";
					sha256 = "0iwd6y2x2nx52hd3bsav3rrhr7dnl4n79ln09picmnh1mp4rrs3l";
				};
			};
			ms-vscode.vscode-typescript-tslint-plugin = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "vscode-typescript-tslint-plugin";
					version = "1.3.4";
					sha256 = "0zbg99x71scpgdyicp7fryxmg51fj2fy0dmfm04zq26s0g0n6gn1";
				};
			};
			akamud.vscode-theme-onedark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "akamud";
					name = "vscode-theme-onedark";
					version = "2.2.3";
					sha256 = "1m6f6p7x8vshhb03ml7sra3v01a7i2p3064mvza800af7cyj3w5m";
				};
			};
			donjayamanne.python-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "python-extension-pack";
					version = "1.7.0";
					sha256 = "1rvhhmbl8dn1klni3hj57fbybnsli88hip6jfncd9k0mfgmb00vv";
				};
			};
			awwsky.csharpfixformatfixed = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "awwsky";
					name = "csharpfixformatfixed";
					version = "0.0.90";
					sha256 = "0616gdg6l5lrcyh71ax7lpn8v36g5f8bpaly9qn14parack04lx2";
				};
			};
			Shan.code-settings-sync = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Shan";
					name = "code-settings-sync";
					version = "3.4.3";
					sha256 = "0wdlf34bsyihjz469sam76wid8ylf0zx2m1axnwqayngi3y8nrda";
				};
			};
			aaron-bond.better-comments = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "aaron-bond";
					name = "better-comments";
					version = "3.0.0";
					sha256 = "17b7m50z0fbifs8azgn6ygcmgwclssilw9j8nb178szd6zrjz2vf";
				};
			};
			johnpapa.Angular2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnpapa";
					name = "Angular2";
					version = "13.0.0";
					sha256 = "14h954ys2la9lcqyak0yf6agkabkhi7rzb6rr0lyn6qasyvswszg";
				};
			};
			magicstack.MagicPython = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "magicstack";
					name = "MagicPython";
					version = "1.1.0";
					sha256 = "08zwzjw2j2ilisasryd73x63ypmfv7pcap66fcpmkmnyb7jgs6nv";
				};
			};
			lonefy.vscode-JS-CSS-HTML-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lonefy";
					name = "vscode-JS-CSS-HTML-formatter";
					version = "0.2.3";
					sha256 = "06vivclp58wzmqcx6s6pl8ndqina7p995dr59aj9fk65xihkaagy";
				};
			};
			xdebug.php-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xdebug";
					name = "php-pack";
					version = "1.0.3";
					sha256 = "07d5izyw7mdzknliiwrybyxs0rhy7p0maq23qydmdwjl1dy49ckb";
				};
			};
			shd101wyy.markdown-preview-enhanced = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shd101wyy";
					name = "markdown-preview-enhanced";
					version = "0.6.3";
					sha256 = "0zn7yk9psmaxk2krbrrfjfgcpmgr15ldf9fn5sc7j7kb1r2q89bl";
				};
			};
			pranaygp.vscode-css-peek = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pranaygp";
					name = "vscode-css-peek";
					version = "4.2.0";
					sha256 = "0dpkp3xs8jd826h2aa9xlfilsj4yv8q6r9cs350ljrpcyj7wrlpq";
				};
			};
			mhutchie.git-graph = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mhutchie";
					name = "git-graph";
					version = "1.30.0";
					sha256 = "000zhgzijf3h6abhv4p3cz99ykj6489wfn81j0s691prr8q9lxxh";
				};
			};
			mikestead.dotenv = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mikestead";
					name = "dotenv";
					version = "1.0.1";
					sha256 = "0rs57csczwx6wrs99c442qpf6vllv2fby37f3a9rhwc8sg6849vn";
				};
			};
			msjsdiag.vscode-react-native = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "msjsdiag";
					name = "vscode-react-native";
					version = "1.9.2";
					sha256 = "01jazri8949jlgk2ykicapn5aj46pb31vf4pf8nsnis53xzkp88p";
				};
			};
			redhat.vscode-xml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-xml";
					version = "0.21.2022070713";
					sha256 = "1057d9s6xab12gp25jx5pykjyglv60vj55gf6phzyy8lsq09w62q";
				};
			};
			eg2.tslint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eg2";
					name = "tslint";
					version = "1.0.47";
					sha256 = "17i1j062jd3w2768w3mmqc92a51vqczg5k7rc605b7w92hr04ddp";
				};
			};
			MS-CEINTL.vscode-language-pack-es = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-es";
					version = "1.69.7060944";
					sha256 = "0y2avhfpyqvz15c2lpxy3l9wxmgch2s2pwav93frlrl2hvjv5hpg";
				};
			};
			wayou.vscode-todo-highlight = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wayou";
					name = "vscode-todo-highlight";
					version = "1.0.5";
					sha256 = "1sg4zbr1jgj9adsj3rik5flcn6cbr4k2pzxi446rfzbzvcqns189";
				};
			};
			ms-vscode-remote.vscode-remote-extensionpack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "vscode-remote-extensionpack";
					version = "0.21.0";
					sha256 = "14l8h84kvnkbqwmw875qa6y25hhxvx1dsg0g07gdl6n8cv5kvy2g";
				};
			};
			rebornix.Ruby = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rebornix";
					name = "Ruby";
					version = "0.28.1";
					sha256 = "179g7nc6mf5rkha75v7rmb3vl8x4zc6qk1m0wn4pgylkxnzis18w";
				};
			};
			alefragnani.project-manager = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alefragnani";
					name = "project-manager";
					version = "12.6.0";
					sha256 = "1nln4dqqf8dwkga2ys2jyjjp3grf5kk2z8xvyhx4c4bq5ilwg5bg";
				};
			};
			platformio.platformio-ide = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "platformio";
					name = "platformio-ide";
					version = "2.5.0";
					sha256 = "1vy97a35vbi0d5jb3f5v3zrbghs4pipia84rz83kkfljq7cjm7wh";
				};
			};
			humao.rest-client = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "humao";
					name = "rest-client";
					version = "0.25.0";
					sha256 = "1j2gzagl5hyy7ry4nn595z0xzr7wbaq9qrm32p0fj1bgk3r6ib5z";
				};
			};
			ms-python.anaconda-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-python";
					name = "anaconda-extension-pack";
					version = "1.0.1";
					sha256 = "1vgqzhaqr0ylraw1x87a0r3kd3d37cm7qxxsl9iclb9xfsm70vf5";
				};
			};
			njpwerner.autodocstring = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "njpwerner";
					name = "autodocstring";
					version = "0.6.1";
					sha256 = "11vsvr3pggr6xn7hnljins286x6f5am48lx4x8knyg8r7dp1r39l";
				};
			};
			hollowtree.vue-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hollowtree";
					name = "vue-snippets";
					version = "1.0.4";
					sha256 = "0vy6k54169hf3v60prp5wr7lz1b0fp028a3sw1bpgl4b101m2011";
				};
			};
			GrapeCity.gc-excelviewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GrapeCity";
					name = "gc-excelviewer";
					version = "4.2.55";
					sha256 = "0wavsr1jmi8fli0839livcvl04sj0gc657kcm8nf2a4865jplyf8";
				};
			};
			KevinRose.vsc-python-indent = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "KevinRose";
					name = "vsc-python-indent";
					version = "1.17.0";
					sha256 = "14vf5p7pn2zgi4lhp6vkndclcxlw3lfdz0immi05gjyx20gp69i1";
				};
			};
			steoates.autoimport = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "steoates";
					name = "autoimport";
					version = "1.5.4";
					sha256 = "0rh5l4f4lcfanj30cd4xp84955ppnl7haglpl99vnd98kcj308pf";
				};
			};
			MS-CEINTL.vscode-language-pack-ru = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-ru";
					version = "1.69.7060956";
					sha256 = "0065zkm005lqyk698h0736pkx88c34ak5jx8vz33zfqg7mgpdf4j";
				};
			};
			ritwickdey.live-sass = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ritwickdey";
					name = "live-sass";
					version = "3.0.0";
					sha256 = "0hmvzfi6r73s91s2pvbalx42hzyi5f7ac2rx6h35q8r0cmkvs842";
				};
			};
			dbaeumer.jshint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dbaeumer";
					name = "jshint";
					version = "0.11.0";
					sha256 = "1qjzjfr8108g01ybmmn40490zpzirxcfhkcl57lx39w5bm26r696";
				};
			};
			thekalinga.bootstrap4-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "thekalinga";
					name = "bootstrap4-vscode";
					version = "6.1.0";
					sha256 = "1i8gbx7s1mvy1v9l3z34gcbymbmvp817b2hv9mp5k45inp53vw3z";
				};
			};
			alefragnani.Bookmarks = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alefragnani";
					name = "Bookmarks";
					version = "13.3.0";
					sha256 = "0mia2q1al9n0dj4icq0gcl07im7ix2090nj99q9jy5xwcavzpavj";
				};
			};
			Mikael.Angular-BeastCode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Mikael";
					name = "Angular-BeastCode";
					version = "10.0.3";
					sha256 = "1pw4wb78czl4znvy5fqsr675c7dmkh1hfigmkrw4dwxji0q4b2iz";
				};
			};
			firefox-devtools.vscode-firefox-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "firefox-devtools";
					name = "vscode-firefox-debug";
					version = "2.9.7";
					sha256 = "0pbgq783ylmiik4s0dzza50bckhw8j4jyalc4s0jm4dns3n8pch2";
				};
			};
			MS-CEINTL.vscode-language-pack-pt-BR = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-pt-BR";
					version = "1.69.7060944";
					sha256 = "1qb9jsk9ivaz1bxqpj7d6jpwz14zp32xpi192q769s4ih6w6zgcl";
				};
			};
			Gruntfuggly.todo-tree = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Gruntfuggly";
					name = "todo-tree";
					version = "0.0.215";
					sha256 = "0lyaijsvi1gqidpn8mnnfc0qsnd7an8qg5p2m7l24c767gllkbsq";
				};
			};
			ms-kubernetes-tools.vscode-kubernetes-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-kubernetes-tools";
					name = "vscode-kubernetes-tools";
					version = "1.3.10";
					sha256 = "0jxscmgvpsm36zjdy99y218dj7wv19jsrqap8h0saks0l0k44via";
				};
			};
			tht13.html-preview-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tht13";
					name = "html-preview-vscode";
					version = "0.2.5";
					sha256 = "0k75ivigzjfq8y4xwwrgs2iy913plkwp2a68f0i4bkz9kx39wq6v";
				};
			};
			onecentlin.laravel-blade = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "onecentlin";
					name = "laravel-blade";
					version = "1.32.0";
					sha256 = "1sivvfhvxx19pq7gi8ikizgb34x0yn0f1x2piy0z5srl7xjqhirk";
				};
			};
			mechatroner.rainbow-csv = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mechatroner";
					name = "rainbow-csv";
					version = "2.4.0";
					sha256 = "0idl63rfn068zamyx5mw3524k3pb98gv32dfbrszxyrrx4kbh1fd";
				};
			};
			danielpinto8zz6.c-cpp-compile-run = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "danielpinto8zz6";
					name = "c-cpp-compile-run";
					version = "1.0.15";
					sha256 = "07mszrsinjwd5sg5i6g20lzrwxqqjh4d7r8mnrb6wv0w7wjik775";
				};
			};
			GitHub.copilot = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitHub";
					name = "copilot";
					version = "1.31.6194";
					sha256 = "1305l7alabs8bw6yj7m3pcvihbrag1gmmmg80pb0qxzgj7g2xdd1";
				};
			};
			HashiCorp.terraform = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HashiCorp";
					name = "terraform";
					version = "2.23.0";
					sha256 = "1mip3rv416asgcn6x2vdmyyhi0ciz1h722s3hr8zlgrskv0pzq97";
				};
			};
			ms-dotnettools.vscode-dotnet-runtime = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-dotnettools";
					name = "vscode-dotnet-runtime";
					version = "1.5.0";
					sha256 = "1rx2605zc1k5ygx3c0nsya2svg1n3gbagn08knnhqlki3zkil1gx";
				};
			};
			James-Yu.latex-workshop = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "James-Yu";
					name = "latex-workshop";
					version = "8.27.2";
					sha256 = "1aq98sqmfsglr0mi1ls4xp7fikhq61ammq9awg3bfcp5r3lx7jxi";
				};
			};
			burkeholland.simple-react-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "burkeholland";
					name = "simple-react-snippets";
					version = "1.2.6";
					sha256 = "03pas6jc5j86w4z9a0bfggpcilkkpkrcgnkijjc30a3kmv5w9lng";
				};
			};
			wix.vscode-import-cost = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wix";
					name = "vscode-import-cost";
					version = "3.3.0";
					sha256 = "0wl8vl8n0avd6nbfmis0lnlqlyh4yp3cca6kvjzgw5xxdc5bl38r";
				};
			};
			mtxr.sqltools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mtxr";
					name = "sqltools";
					version = "0.23.0";
					sha256 = "0gkm1m7jss25y2p2h6acm8awbchyrsqfhmbg70jaafr1dfxkzfir";
				};
			};
			redhat.vscode-commons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-commons";
					version = "0.0.6";
					sha256 = "1b8nlhbrsg3kj27f1kgj8n5ak438lcfq5v5zlgf1hzisnhmcda5n";
				};
			};
			MS-vsliveshare.vsliveshare-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-vsliveshare";
					name = "vsliveshare-pack";
					version = "0.4.0";
					sha256 = "09h2yxpmbvxa3mz5wdnpb35h437f0z6j0n3blsb0d93jlwx5ydy5";
				};
			};
			WallabyJs.quokka-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "WallabyJs";
					name = "quokka-vscode";
					version = "1.0.487";
					sha256 = "0rzzllk4zgx1g63rxc4ji8q637zc1h1r8nfhq7rwcx132pxbp5z3";
				};
			};
			jcbuisson.vue = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jcbuisson";
					name = "vue";
					version = "0.1.5";
					sha256 = "03gkxgqgyjsaf1c080nn2q211zm12mwad1g5070z53wc9gvfy2mc";
				};
			};
			johnpapa.winteriscoming = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnpapa";
					name = "winteriscoming";
					version = "1.4.4";
					sha256 = "15yqncwn2kadm4r47q8lvqk8qwasdjrrb6s7blcfi3s3nl3w5g73";
				};
			};
			GitHub.codespaces = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitHub";
					name = "codespaces";
					version = "1.9.2";
					sha256 = "0yqsxx13bakbhb3npixn2wrrkwk53jzzz8k6jzq2b5s7an80r2bi";
				};
			};
			codezombiech.gitignore = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "codezombiech";
					name = "gitignore";
					version = "0.7.0";
					sha256 = "0fm4sxx1cb679vn4v85dw8dfp5x0p74m9p2b56gqkvdap0f2q351";
				};
			};
			johnpapa.vscode-peacock = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnpapa";
					name = "vscode-peacock";
					version = "4.0.1";
					sha256 = "1ckm0i8hkfh6zd7bmw1k0fbr3ynn148nbzpxm88whsdhm4wxi1d1";
				};
			};
			rust-lang.rust = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rust-lang";
					name = "rust";
					version = "0.7.8";
					sha256 = "039ns854v1k4jb9xqknrjkj8lf62nfcpfn0716ancmjc4f0xlzb3";
				};
			};
			ms-vscode.sublime-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "sublime-keybindings";
					version = "4.0.10";
					sha256 = "0l8z0sv3432qrzh6118km7xr7g93fajmjihw8md47kfsdl9c4xxg";
				};
			};
			wingrunr21.vscode-ruby = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wingrunr21";
					name = "vscode-ruby";
					version = "0.28.0";
					sha256 = "1gab5cka87zw7i324rz9gmv423rf5sylsq1q1dhfkizmrpwzaxqz";
				};
			};
			mgmcdermott.vscode-language-babel = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mgmcdermott";
					name = "vscode-language-babel";
					version = "0.0.36";
					sha256 = "0v2xqry7pgwnzxi534v2rrbkfz9gvvbyc2px2g0xpbaaz3rrz6kd";
				};
			};
			tomoki1207.pdf = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tomoki1207";
					name = "pdf";
					version = "1.2.0";
					sha256 = "1bcj546bp0w4yndd0qxwr8grhiwjd1jvf33jgmpm0j96y34vcszz";
				};
			};
			vscjava.vscode-spring-initializr = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-spring-initializr";
					version = "0.10.2022070703";
					sha256 = "1m42q545p0f5lrvam2gyadqr2l2x4396rixly9n58rjb4mny5w91";
				};
			};
			hbenl.vscode-test-explorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hbenl";
					name = "vscode-test-explorer";
					version = "2.21.1";
					sha256 = "022lnkq278ic0h9ggpqcwb3x3ivpcqjimhgirixznq0zvwyrwz3w";
				};
			};
			vadimcn.vscode-lldb = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vadimcn";
					name = "vscode-lldb";
					version = "1.7.0";
					sha256 = "0sdy261fkccff13i0s6kiykkwisinasxy1n23m0xmw72i9w31rhf";
				};
			};
			MS-CEINTL.vscode-language-pack-ko = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-ko";
					version = "1.69.7060956";
					sha256 = "10wl0ab25gzy0kyf7ar20ajfhkcyq2a26fpxpk51hnaxvqhfjnr5";
				};
			};
			_2gua.rainbow-brackets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "2gua";
					name = "rainbow-brackets";
					version = "0.0.6";
					sha256 = "1m5c7jjxphawh7dmbzmrwf60dz4swn8c31svbzb5nhaazqbnyl2d";
				};
			};
			sidthesloth.html5-boilerplate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sidthesloth";
					name = "html5-boilerplate";
					version = "1.1.1";
					sha256 = "1nj015hj34slzpwfs067mfb8jms6hrr8j0rq81s1ddijbhyfbdw0";
				};
			};
			monokai.theme-monokai-pro-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "monokai";
					name = "theme-monokai-pro-vscode";
					version = "1.1.20";
					sha256 = "0ddwqsvsqdjblmb0xlad17czy2837g27ymwvzissz4b9r111xyhx";
				};
			};
			Pivotal.vscode-spring-boot = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Pivotal";
					name = "vscode-spring-boot";
					version = "1.36.0";
					sha256 = "1c15rja2nb03wzasqcaywvxwc8rj89v7sc0vacc1yscppmgrjkcx";
				};
			};
			MS-CEINTL.vscode-language-pack-fr = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-fr";
					version = "1.69.7060951";
					sha256 = "0x1h3g0hgqdp1k5f7v5kc1362p92ik3vd9r52ghh9pgl10gi874a";
				};
			};
			jchannon.csharpextensions = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jchannon";
					name = "csharpextensions";
					version = "1.3.1";
					sha256 = "0bkg5c9c5mlndpfx75gma9rz8xi66x0p4ypn5nxxjjwix8msmldn";
				};
			};
			donjayamanne.python-environment-manager = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "python-environment-manager";
					version = "1.0.4";
					sha256 = "16lnkzw96j30lk7i39r1dkdcimmc3kcqq4ri8c77562ay765pfhk";
				};
			};
			sdras.night-owl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sdras";
					name = "night-owl";
					version = "2.0.1";
					sha256 = "0c8zp946ynf7vvlj2w1xnp71cgpplgw5vb0b5s39yqa6bxaxr9q2";
				};
			};
			sdras.vue-vscode-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sdras";
					name = "vue-vscode-snippets";
					version = "3.1.1";
					sha256 = "0qvxvcph57ax70wg661aqkqbhcv7zdjzwpqw4kiykc0cjs5zwpws";
				};
			};
			Equinusocio.vsc-community-material-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Equinusocio";
					name = "vsc-community-material-theme";
					version = "1.4.4";
					sha256 = "005l4pr9x3v6x8450jn0dh7klv0pv7gv7si955r7b4kh19r4hz9y";
				};
			};
			bradlc.vscode-tailwindcss = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bradlc";
					name = "vscode-tailwindcss";
					version = "0.8.6";
					sha256 = "1qlmmfw9kw3758b0rd5kjb4j80v4aafhhaqamyn50q6y7nw4lpmz";
				};
			};
			donjayamanne.jquerysnippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "jquerysnippets";
					version = "0.0.1";
					sha256 = "1vc9f23njxwqwzwriqr02cd3yal8fq9qvq27873yj089ml6ifkm6";
				};
			};
			Equinusocio.vsc-material-theme-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Equinusocio";
					name = "vsc-material-theme-icons";
					version = "2.3.1";
					sha256 = "1djm4k3hcn4aq63d4mxs2n4ffq5x1qr82q6gxwi5pmabrb0hrb30";
				};
			};
			mitaki28.vscode-clang = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mitaki28";
					name = "vscode-clang";
					version = "0.2.4";
					sha256 = "0sys2h4jvnannlk2q02lprc2ss9nkgh0f0kwa188i7viaprpnx23";
				};
			};
			vsciot-vscode.vscode-arduino = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsciot-vscode";
					name = "vscode-arduino";
					version = "0.4.12";
					sha256 = "0i1kv8xdzzrrrrp9qv9sf4ydjr4k31hg9r9iyy3df63j4pvi6ni3";
				};
			};
			ms-vscode.vscode-typescript-next = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "vscode-typescript-next";
					version = "4.8.20220705";
					sha256 = "1rr7lird8jbrpkzmancivmzl8adra3wpdsjvb8paal8agzpbkm40";
				};
			};
			ms-azuretools.vscode-azurefunctions = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azurefunctions";
					version = "1.7.4";
					sha256 = "1yp1s270sw7jkgjqqk91vc8cc709xsxa3d2v153lbcl04fg6vzrz";
				};
			};
			azemoh.one-monokai = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "azemoh";
					name = "one-monokai";
					version = "0.5.0";
					sha256 = "1rqg3np6jc9lrl9xqq8iq74y4ag3wnj5c0zv9h9ljpk5xzp4rdva";
				};
			};
			Unity.unity-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Unity";
					name = "unity-debug";
					version = "3.0.2";
					sha256 = "1fbms5p3kd1j95rq7m5pfm0vqyqh7ak6hc4x95h1ibab3n4ddl18";
				};
			};
			Syler.sass-indented = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Syler";
					name = "sass-indented";
					version = "1.8.22";
					sha256 = "0mm04wqis8yzl5n2nx909y9afjqqmy27c8c0aggsmf027iczsp4b";
				};
			};
			ms-azuretools.vscode-azureresourcegroups = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azureresourcegroups";
					version = "0.5.4";
					sha256 = "0iyiwpc4lpzq7wdz1fzpjiq4rlbiavql7n0fxvlijnf7h79d78fy";
				};
			};
			ikappas.phpcs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ikappas";
					name = "phpcs";
					version = "1.0.5";
					sha256 = "0j5w69qzmragl8dapffks8sypya2wq02q7rmg0y3n8m1kk244wga";
				};
			};
			vscjava.vscode-spring-boot-dashboard = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-spring-boot-dashboard";
					version = "0.5.2022070700";
					sha256 = "0887ibw344xqp1wl9nk33gdjmbpwkrffls5qp40qf617379x3nk6";
				};
			};
			formulahendry.terminal = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "terminal";
					version = "0.0.10";
					sha256 = "0gj71xy7r82n1pic00xsi04dg7zg0dsxx000s03iq6lnz47s84gn";
				};
			};
			teabyii.ayu = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "teabyii";
					name = "ayu";
					version = "1.0.5";
					sha256 = "1visv44mizfvsysrdby1vrncv1g3qmf45rhjijmbyak2d60nm0gq";
				};
			};
			waderyan.gitblame = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "waderyan";
					name = "gitblame";
					version = "8.2.3";
					sha256 = "0lwpvgg5n6pii0skjaw92cd00rx02y9dlkqsy13irjqkdfm3j6n3";
				};
			};
			xabikos.ReactSnippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xabikos";
					name = "ReactSnippets";
					version = "2.4.0";
					sha256 = "0gbs5pc9wrg7bcn1dakhfid1ancbz1ikz3n31hgawsgais5f931b";
				};
			};
			mohsen1.prettify-json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mohsen1";
					name = "prettify-json";
					version = "0.0.3";
					sha256 = "1spj01dpfggfchwly3iyfm2ak618q2wqd90qx5ndvkj3a7x6rxwn";
				};
			};
			quicktype.quicktype = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "quicktype";
					name = "quicktype";
					version = "12.0.46";
					sha256 = "0mzn1favvrzqcigr74gmy167qak5saskhwcvhf7f00z7x0378dim";
				};
			};
			vincaslt.highlight-matching-tag = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vincaslt";
					name = "highlight-matching-tag";
					version = "0.10.1";
					sha256 = "0b9jpwiyxax783gyr9zhx7sgrdl9wffq34fi7y67vd68q9183jw1";
				};
			};
			Vue.volar = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Vue";
					name = "volar";
					version = "0.38.3";
					sha256 = "1v5vhy928rnfz9qf9fqmh15ac7fv85rl3wl64rd5cmsf3a9b19nn";
				};
			};
			formulahendry.auto-complete-tag = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "auto-complete-tag";
					version = "0.1.0";
					sha256 = "14xmglw17wlzsil9dpbnn96kvzavfds6xmyf4s9crxydm1swpgsz";
				};
			};
			emmanuelbeziat.vscode-great-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "emmanuelbeziat";
					name = "vscode-great-icons";
					version = "2.1.86";
					sha256 = "083bxadyis6h9l59hwfryv1xsqfkinaf5nd0alxxvzmnd3s36dbx";
				};
			};
			MS-CEINTL.vscode-language-pack-de = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-de";
					version = "1.69.7060951";
					sha256 = "1agy9wfm8a453z2yvgxkr9qg7p3kihw46c3bppbz9np3jirnrzqb";
				};
			};
			SonarSource.sonarlint-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SonarSource";
					name = "sonarlint-vscode";
					version = "3.6.0";
					sha256 = "05kzhfarqbk13qbs4y7miyh1kf9pc15wryzc7jab8g821fhq95yk";
				};
			};
			jasonnutter.search-node-modules = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jasonnutter";
					name = "search-node-modules";
					version = "1.3.0";
					sha256 = "10kxx732cg60ncr4x1by6h1nab1a8xa4lh1rbhkwgs3qa44s8q2z";
				};
			};
			ms-mssql.data-workspace-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-mssql";
					name = "data-workspace-vscode";
					version = "0.2.1";
					sha256 = "09wcla3p7njasila1j14p24jgbjg1il45bphs1dq27gvxnp6w8nd";
				};
			};
			onecentlin.laravel5-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "onecentlin";
					name = "laravel5-snippets";
					version = "1.15.0";
					sha256 = "0lqig2w2gi86b3xq198cswnva671j7g4mxxmhwdi8r07djxnp3p1";
				};
			};
			ms-vsts.team = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vsts";
					name = "team";
					version = "1.161.1";
					sha256 = "1qlcc8gl1r8bqvxqhmjp22ir92r248l2bw8fwhh8ifghdbb18552";
				};
			};
			michelemelluso.code-beautifier = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "michelemelluso";
					name = "code-beautifier";
					version = "2.3.3";
					sha256 = "048ghxgd18d78x79d6lw5vv0jaqazpyvpvy6fknqgk5sbz180sj6";
				};
			};
			ahmadawais.shades-of-purple = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ahmadawais";
					name = "shades-of-purple";
					version = "6.13.0";
					sha256 = "01kr8kph3r5rxds6nnz07nssyqwkcygg0jr7yvbr1mg4irwcpjhd";
				};
			};
			ms-mssql.sql-database-projects-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-mssql";
					name = "sql-database-projects-vscode";
					version = "0.17.1";
					sha256 = "1kh0zwbgwwm11wx0j2733jfd0qp3cr9wyickhac3qxds9ngggchi";
				};
			};
			Equinusocio.vsc-material-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Equinusocio";
					name = "vsc-material-theme";
					version = "33.5.0";
					sha256 = "1pr98mx7hji8jlm6ppac693ivbcpybh043w2z8sa3f49v7pksnrf";
				};
			};
			rifi2k.format-html-in-php = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rifi2k";
					name = "format-html-in-php";
					version = "1.7.0";
					sha256 = "0dmq2yyncbszd4xlb3r5ll4f0dzh46p8la77rv5k50gj45y1p3ys";
				};
			};
			liximomo.sftp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "liximomo";
					name = "sftp";
					version = "1.12.10";
					sha256 = "0scg9rsnlif8l7hjd99q2qlv0b5z1dq7zp08b3ipk5x582325hzv";
				};
			};
			aeschli.vscode-css-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "aeschli";
					name = "vscode-css-formatter";
					version = "1.0.2";
					sha256 = "142kkjsnr65gdsxaqj4q6mi3yv2x935cs7qr2sb7mmz6wiwlwlqc";
				};
			};
			yzane.markdown-pdf = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yzane";
					name = "markdown-pdf";
					version = "1.4.4";
					sha256 = "00cjwjwzsv3wx2qy0faqxryirr2hp60yhkrlzsk0avmvb0bm9paf";
				};
			};
			alexcvzz.vscode-sqlite = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alexcvzz";
					name = "vscode-sqlite";
					version = "0.14.1";
					sha256 = "1iaklnhw74iwyjw74prnrx34ba25ra7ld71zlip04lv401329r4c";
				};
			};
			zobo.php-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "zobo";
					name = "php-intellisense";
					version = "1.0.11";
					sha256 = "1ymv8067z49ml1l133cxmk680apjcrj7j5s407w97b4j9z0c3wqj";
				};
			};
			franneck94.c-cpp-runner = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "franneck94";
					name = "c-cpp-runner";
					version = "4.0.3";
					sha256 = "149fhhbf90i7lskaq9qzj8d954j1a6zdfdjpyw9dx809krjk19v3";
				};
			};
			georgewfraser.vscode-javac = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "georgewfraser";
					name = "vscode-javac";
					version = "0.2.42";
					sha256 = "0fj20z8h2p9kbnax7pykvyq4pbwldi86mdb0cc3znrsir5ys06dd";
				};
			};
			ionutvmi.path-autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ionutvmi";
					name = "path-autocomplete";
					version = "1.19.1";
					sha256 = "1ndm5x0f6asmlvv92981j9ciw7w87ahvsl1iyd0gjwd0f45fc6fj";
				};
			};
			ms-vscode.test-adapter-converter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "test-adapter-converter";
					version = "0.1.6";
					sha256 = "0pj4ln8g8dzri766h9grdvhknz2mdzwv0lmzkpy7l9w9xx8jsbsh";
				};
			};
			k--kato.intellij-idea-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "k--kato";
					name = "intellij-idea-keybindings";
					version = "1.5.1";
					sha256 = "16shskxyf1sa4bkwn8s20myi9glsaiyqlbqi3i99zr1rkvgbisjz";
				};
			};
			Pivotal.vscode-boot-dev-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Pivotal";
					name = "vscode-boot-dev-pack";
					version = "0.1.0";
					sha256 = "13hls4g5ikrsa5g3lmbyvhx25m6q953z5zgg3n8xcc00s6kgb7sl";
				};
			};
			Orta.vscode-jest = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Orta";
					name = "vscode-jest";
					version = "4.6.0";
					sha256 = "1dmssylvfzyadyrc061kyycm1zah4z1k02f1v4kb82hpv3kaag91";
				};
			};
			ZainChen.json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ZainChen";
					name = "json";
					version = "2.0.2";
					sha256 = "18pifg17w8zmv3kb74pjxwlyfssq66h3bzsqhgipzdl2mgqd0bcw";
				};
			};
			bungcip.better-toml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bungcip";
					name = "better-toml";
					version = "0.3.2";
					sha256 = "08lhzhrn6p0xwi0hcyp6lj9bvpfj87vr99klzsiy8ji7621dzql3";
				};
			};
			anseki.vscode-color = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "anseki";
					name = "vscode-color";
					version = "0.4.5";
					sha256 = "01nl3mpad91xdwz5f71s6b675wvhnj481sjpk8qlvzws1an4mjf5";
				};
			};
			rbbit.typescript-hero = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rbbit";
					name = "typescript-hero";
					version = "3.0.0";
					sha256 = "1jf0447balk4ym7l8l1x1qa6vy06v10q433ajz371q64xp0xp493";
				};
			};
			jebbs.plantuml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jebbs";
					name = "plantuml";
					version = "2.17.3";
					sha256 = "1i78q44y5qriai1r4y0icdv5gl5v9wzhm0rkwp2pvk0vwr4v2fks";
				};
			};
			nrwl.angular-console = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nrwl";
					name = "angular-console";
					version = "17.18.7";
					sha256 = "09pgs4m82ln29r3fdhxnfcyxhl6ibkwrj6fqn06fylv2f3xbryiy";
				};
			};
			qinjia.view-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "qinjia";
					name = "view-in-browser";
					version = "0.0.5";
					sha256 = "1vwn6g1zbf3cv30kk1s3066pvw4y4hkhc2pvhyw8vdaxdf1d730v";
				};
			};
			ms-vscode.azurecli = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "azurecli";
					version = "0.5.0";
					sha256 = "0ijkz4m93kfgkh3rcjvzh1rharc0n1fx0kj89zjgrdaplbhd9x16";
				};
			};
			zxh404.vscode-proto3 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "zxh404";
					name = "vscode-proto3";
					version = "0.5.5";
					sha256 = "08gjq2ww7pjr3ck9pyp5kdr0q6hxxjy3gg87aklplbc9bkfb0vqj";
				};
			};
			cssho.vscode-svgviewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cssho";
					name = "vscode-svgviewer";
					version = "2.0.0";
					sha256 = "06swlqiv3gc7plcbmzz795y6zwpxsdhg79k1n3jj6qngfwnv2p6z";
				};
			};
			shardulm94.trailing-spaces = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shardulm94";
					name = "trailing-spaces";
					version = "0.3.1";
					sha256 = "0h30zmg5rq7cv7kjdr5yzqkkc1bs20d72yz9rjqag32gwf46s8b8";
				};
			};
			leizongmin.node-module-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "leizongmin";
					name = "node-module-intellisense";
					version = "1.5.0";
					sha256 = "062fw12h6v34sridp1hdrr32hfj828s1n14l5bfzvqix38mpn1za";
				};
			};
			Atlassian.atlascode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Atlassian";
					name = "atlascode";
					version = "2.10.12";
					sha256 = "1wzpcc7w971nwss9b4ipk5ac41w07j03nyknqaa309yk96v2x079";
				};
			};
			mkaufman.HTMLHint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mkaufman";
					name = "HTMLHint";
					version = "0.10.0";
					sha256 = "1vk4v99a0sz02vk1qcqw7gn8mz0xq16vi24h90zzh34za3110as2";
				};
			};
			ms-azuretools.vscode-azureappservice = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azureappservice";
					version = "0.24.3";
					sha256 = "0wv5hs69a5vkin8qpy56avcpqspcqlpcqx3jxyam9jf78fnmql8g";
				};
			};
			icrawl.discord-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "icrawl";
					name = "discord-vscode";
					version = "5.8.0";
					sha256 = "0r9n2g5rif4y2619wccjqh3pn9rljb3yhblz09pdksmfi2ifakr1";
				};
			};
			rangav.vscode-thunder-client = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rangav";
					name = "vscode-thunder-client";
					version = "1.16.6";
					sha256 = "11fan0ayhsw62qlaz4h9l6kd0lrzy3f4d6h7nh1jq3fskfwmqpx6";
				};
			};
			salesforce.salesforcedx-vscode-core = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-core";
					version = "55.4.0";
					sha256 = "1dac76gzz528b7mhkqr091mzy64bq2z4zql369nabpc3isj296yx";
				};
			};
			ryannaddy.laravel-artisan = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ryannaddy";
					name = "laravel-artisan";
					version = "0.0.28";
					sha256 = "1pv2nxdmkrzqfw09w6kmvdqksmf8a9fqvhn3q8xfvbim28k6l9l7";
				};
			};
			ziyasal.vscode-open-in-github = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ziyasal";
					name = "vscode-open-in-github";
					version = "1.3.6";
					sha256 = "156gaj7gcm0588hmwkigkmidf0jxnrq2kvaigf3kszisz05854dq";
				};
			};
			formulahendry.vscode-mysql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "vscode-mysql";
					version = "0.4.1";
					sha256 = "0rd2sy9343xz0v1dhs55ph30acz9k4jhh7ix81qv8xs417qr8z31";
				};
			};
			whizkydee.material-palenight-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "whizkydee";
					name = "material-palenight-theme";
					version = "2.0.2";
					sha256 = "1lh4bz8nfxshi90h1dbliw3mi9sh5m5z46f2dhm5lam4xxfjkwgz";
				};
			};
			GraphQL.vscode-graphql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GraphQL";
					name = "vscode-graphql";
					version = "0.4.14";
					sha256 = "072mk5jz0z5m9ip26hc1piil0macf1yq6fpjrvfn4wxvmdf2pg8b";
				};
			};
			dongli.python-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dongli";
					name = "python-preview";
					version = "0.0.4";
					sha256 = "08z0r8v5nkhg1mx7846p7s8mdnhx7w5ijbmbxav09yicxld04xz7";
				};
			};
			msazurermtools.azurerm-vscode-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "msazurermtools";
					name = "azurerm-vscode-tools";
					version = "0.15.7";
					sha256 = "11w14qgq53kgfrxqha2w5il97gcng52nj6k3qpz8vsjyaap16pni";
				};
			};
			pflannery.vscode-versionlens = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pflannery";
					name = "vscode-versionlens";
					version = "1.0.10";
					sha256 = "0axj7446l46n6dpc5y8gvvrlz46pxr0ps095qbh21kpa86gf9c7q";
				};
			};
			salesforce.salesforcedx-vscode-apex = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-apex";
					version = "55.4.0";
					sha256 = "17r02kw688gg599km2gwdzhg4x58blhzmgj8hspklh24imy4z1hl";
				};
			};
			EQuimper.react-native-react-redux = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "EQuimper";
					name = "react-native-react-redux";
					version = "2.0.6";
					sha256 = "0r6kjihk02g0x3048m05vifk7xidvx93q6pdxdrnkp0fkphvbsn1";
				};
			};
			Nash.awesome-flutter-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Nash";
					name = "awesome-flutter-snippets";
					version = "3.0.3";
					sha256 = "1kmklahzzng7fy1xgqmyzphyfpy2dppfbvqwbsw3al2s0psynxd0";
				};
			};
			RobbOwen.synthwave-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "RobbOwen";
					name = "synthwave-vscode";
					version = "0.1.11";
					sha256 = "1r2qqlm3alb9ysjiyaqakd01r87kmns8y1qfndv6v24aj2l3syww";
				};
			};
			KnisterPeter.vscode-github = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "KnisterPeter";
					name = "vscode-github";
					version = "0.30.7";
					sha256 = "1b1hm6z795n05mpy1b0cf0578bi8yr4d0h4w177m98ka170shz2j";
				};
			};
			hdg.live-html-previewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hdg";
					name = "live-html-previewer";
					version = "0.3.0";
					sha256 = "0hv5plh44q97355j5la83r8hjsxpv9d173mba34xr4p82a3pcq5p";
				};
			};
			wesbos.theme-cobalt2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wesbos";
					name = "theme-cobalt2";
					version = "2.2.5";
					sha256 = "1m823pqsdb27rarwkk2sjnqlm84yq9a5cn6np6phx6jh87kpwqgm";
				};
			};
			ms-vscode.notepadplusplus-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "notepadplusplus-keybindings";
					version = "1.0.7";
					sha256 = "148mz6jvlq7jycsyf8fxczbv90bmnj1gzb7p9mvfdprb38kf6bw8";
				};
			};
			kisstkondoros.vscode-gutter-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kisstkondoros";
					name = "vscode-gutter-preview";
					version = "0.30.0";
					sha256 = "1plbdr5dg0x3ayjkxza1449b3mrgvyhl17layjnd2pp7fv8ib84k";
				};
			};
			MS-CEINTL.vscode-language-pack-zh-hant = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-zh-hant";
					version = "1.69.7060951";
					sha256 = "033jmg07jqbyjwc0fyvrcfr6d04wa9f72bgcqgzdwd6w37lad0py";
				};
			};
			salesforce.salesforcedx-vscode-lightning = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-lightning";
					version = "55.4.0";
					sha256 = "1cap0dj04k5xz4dsv3hvj5cmwgd69x5ghcsczcl39g5pns1nn8qg";
				};
			};
			salesforce.salesforcedx-vscode-visualforce = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-visualforce";
					version = "55.4.0";
					sha256 = "14dd5yzs2r74jyvp9d39661d6d9v1ghb45ni1bfgbbzrzg8j5xf3";
				};
			};
			johnpapa.angular-essentials = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnpapa";
					name = "angular-essentials";
					version = "13.0.0";
					sha256 = "1fnv7ykwdbady34gdz06nywni533p0xg5bsr6235i2pyzhaj3i1h";
				};
			};
			usernamehw.errorlens = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "usernamehw";
					name = "errorlens";
					version = "3.5.1";
					sha256 = "17xbbr5hjrs67yazicb9qillbkp3wnaccjpnl1jlp07s0n7q4f8f";
				};
			};
			neilbrayfield.php-docblocker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "neilbrayfield";
					name = "php-docblocker";
					version = "2.7.0";
					sha256 = "0zgkydbnda821mjaiwddsyr4l6ycy0adf27a0qph1gjnjmj862xk";
				};
			};
			salesforce.salesforcedx-vscode-apex-debugger = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-apex-debugger";
					version = "55.4.0";
					sha256 = "19dbygxpwr8m2hjsjd78fvwgb96ajvpdpjvldh4l896m71smds0q";
				};
			};
			ms-vscode.atom-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "atom-keybindings";
					version = "3.0.9";
					sha256 = "04jqc6i5qybkl7y90m40f7fi8njdafdgmpvna8z7cvz9ibjbpv21";
				};
			};
			kleber-swf.unity-code-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kleber-swf";
					name = "unity-code-snippets";
					version = "1.3.0";
					sha256 = "1nllkgk8vc1ckdzyc48bzcbsn8435am1y6kq0bs6pl7ihpl9lb4s";
				};
			};
			xaver.clang-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xaver";
					name = "clang-format";
					version = "1.9.0";
					sha256 = "0bwc4lpcjq1x73kwd6kxr674v3rb0d2cjj65g3r69y7gfs8yzl5b";
				};
			};
			Pivotal.vscode-manifest-yaml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Pivotal";
					name = "vscode-manifest-yaml";
					version = "1.36.0";
					sha256 = "0d4k13ijp1w035623218h7ml9wpibqpyg8lyq412bdw0rw9fwwgq";
				};
			};
			salesforce.salesforcedx-vscode-lwc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-lwc";
					version = "55.4.0";
					sha256 = "0va05vg26fbqwyf5fsaa33wzq8q8ibhwdh7gdsr91b2v74yy9x8p";
				};
			};
			ms-vscode.hexeditor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "hexeditor";
					version = "1.9.7";
					sha256 = "1hv0am6y4d4dggq8viw4f5x6mavah11dqrrxa15lwm2a5ias93xx";
				};
			};
			codingyu.laravel-goto-view = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "codingyu";
					name = "laravel-goto-view";
					version = "1.3.7";
					sha256 = "05r1mg7kn15cvaqzmc1hqz7xyywi17cdp1h114hhx3yphd1i9s24";
				};
			};
			salesforce.salesforcedx-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode";
					version = "55.4.0";
					sha256 = "0z3isdjwn36myg95ax7ybl7i7nzf5166km97alz928bzv2mjmvvc";
				};
			};
			brapifra.phpserver = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "brapifra";
					name = "phpserver";
					version = "3.0.2";
					sha256 = "067s1jy8bmlsjp0rnp24r1hw0d0hy6nbfq2ga526q27gp5plh3f9";
				};
			};
			salesforce.salesforcedx-vscode-apex-replay-debugger = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-apex-replay-debugger";
					version = "55.4.0";
					sha256 = "0j1s88lf8c22h1spikl75vskbxkxcki5dpj2i3dm7ll768bgaj74";
				};
			};
			ms-azuretools.vscode-cosmosdb = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-cosmosdb";
					version = "0.19.2";
					sha256 = "0c73srqyafnbqh7jibl7xixg3kd4jqxmpqahri4l5qc83lf88ccp";
				};
			};
			sibiraj-s.vscode-scss-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sibiraj-s";
					name = "vscode-scss-formatter";
					version = "2.4.3";
					sha256 = "160waf5xx46a8a6cyygym5s3iz3phwqy6yzjmk2mgfx2sy2dakyq";
				};
			};
			mrmlnc.vscode-scss = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-scss";
					version = "0.10.0";
					sha256 = "08kdvg4p0aysf7wg1qfbri59cipllgf69ph1x7aksrwlwjmsps12";
				};
			};
			Pivotal.vscode-concourse = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Pivotal";
					name = "vscode-concourse";
					version = "1.36.0";
					sha256 = "0mb2jb35vqapcxc5gb2x0s78qnwq4r26r2vzczdfw1q749h6p55c";
				};
			};
			jmrog.vscode-nuget-package-manager = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jmrog";
					name = "vscode-nuget-package-manager";
					version = "1.1.6";
					sha256 = "0vjl3lwc73zc6gg3czgdixb0nhcv3sw7yjhadnpccygmanndki30";
				};
			};
			hediet.vscode-drawio = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hediet";
					name = "vscode-drawio";
					version = "1.6.4";
					sha256 = "18mh7jn4hbn1fxkik41j3hsga9i5lfgli07kkv59s2jm9wb1smpr";
				};
			};
			ms-edgedevtools.vscode-edge-devtools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-edgedevtools";
					name = "vscode-edge-devtools";
					version = "2.1.0";
					sha256 = "1gki7466hv6cldd2jqbl3433rl94x3k7ix71dnhrm5lr433451vy";
				};
			};
			Tobiah.unity-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tobiah";
					name = "unity-tools";
					version = "1.2.12";
					sha256 = "1ydxhiir4gadvz0mn783lq0vvsyh8fq8i7i4nfdw2m3dn945pija";
				};
			};
			felipecaputo.git-project-manager = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "felipecaputo";
					name = "git-project-manager";
					version = "1.8.2";
					sha256 = "02d0hdqyd9pnad986ymjdgdma3g97mzrx6pa9fi8cn0pzkaxp6qz";
				};
			};
			k--kato.docomment = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "k--kato";
					name = "docomment";
					version = "0.1.31";
					sha256 = "0hgykx8q4w6hif7i0pf54hkkzmiylrbmcz231biipgsv3hclnk9r";
				};
			};
			file-icons.file-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "file-icons";
					name = "file-icons";
					version = "1.0.29";
					sha256 = "05x45f9yaivsz8a1ahlv5m8gy2kkz71850dhdvwmgii0vljc8jc6";
				};
			};
			donjayamanne.git-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "git-extension-pack";
					version = "0.1.3";
					sha256 = "0j4mq15msbr191az0fyv0q4dbcrsacv4ydim2920p4cml9cqgnw3";
				};
			};
			donjayamanne.jupyter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "jupyter";
					version = "1.1.9";
					sha256 = "1nzrsh8s2b929h2zad3ain8bc7gfwf41pbsnrhdbq80mm8wcyf78";
				};
			};
			peakchen90.open-html-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "peakchen90";
					name = "open-html-in-browser";
					version = "2.1.9";
					sha256 = "045ggc81rfl2xs9wwzvdqszcygvpa5lm5hkn2lzdbp4b9ma2m9d8";
				};
			};
			redhat.fabric8-analytics = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "fabric8-analytics";
					version = "0.3.6";
					sha256 = "06d7yvracfx1p6rzh8x32b24gjf1984gjp5x3rw2b82wda0bn3fq";
				};
			};
			pnp.polacode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pnp";
					name = "polacode";
					version = "0.3.4";
					sha256 = "0l9cm4jrjjrgrsqc0n0awi0xbgyk4sp08pddw5bnfnrsxwhs0kmv";
				};
			};
			tombonnike.vscode-status-bar-format-toggle = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tombonnike";
					name = "vscode-status-bar-format-toggle";
					version = "3.0.0";
					sha256 = "1raz2rmqqx6f17070x9mqd186gz1ihqp26dxgjkdr1zvik8xb6bn";
				};
			};
			wmaurer.change-case = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wmaurer";
					name = "change-case";
					version = "1.0.0";
					sha256 = "0dxsdahyivx1ghxs6l9b93filfm8vl5q2sa4g21fiklgdnaf7pxl";
				};
			};
			dzannotti.vscode-babel-coloring = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dzannotti";
					name = "vscode-babel-coloring";
					version = "0.0.4";
					sha256 = "0hzyb74vg1a6y91cyxab2qjxgqgjwszz7x4n375pbqmk1kyd2jb1";
				};
			};
			josetr.cmake-language-support-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "josetr";
					name = "cmake-language-support-vscode";
					version = "0.0.4";
					sha256 = "02z297823whvz1wnwx6pbcygv4cjddlkcdysln5sss109x8pgarq";
				};
			};
			JuanBlanco.solidity = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JuanBlanco";
					name = "solidity";
					version = "0.0.139";
					sha256 = "07b8jp74mhmcba9cmhml5zlrrm9rsqhly52f8ypdb89ca4vblh44";
				};
			};
			stylelint.vscode-stylelint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "stylelint";
					name = "vscode-stylelint";
					version = "1.2.2";
					sha256 = "00v31vsp6nnw6zvv6a854cvzh63y9l712z57hh7na4x9if9pk9bg";
				};
			};
			MehediDracula.php-namespace-resolver = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MehediDracula";
					name = "php-namespace-resolver";
					version = "1.1.9";
					sha256 = "1fqxsxs8sg6kpxh2yksvgwwzqfi436x2y8h2gqxiqmxfln8k21b2";
				};
			};
			hars.CppSnippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hars";
					name = "CppSnippets";
					version = "0.0.15";
					sha256 = "0i9gxjqdip57d08r88pnjc2mbnlrj811i2k6vg1mcwjgrhll8xr9";
				};
			};
			foxundermoon.shell-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "foxundermoon";
					name = "shell-format";
					version = "7.2.2";
					sha256 = "00wc0y2wpdjs2pbxm6wj9ghhfsvxyzhw1vjvrnn1jfyl4wh3krvi";
				};
			};
			GitHub.remotehub = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitHub";
					name = "remotehub";
					version = "0.36.0";
					sha256 = "09kwyb49n4dsmsm0iw7x8rl5fm0kb4klw11mfrwagypl5fr6kkfg";
				};
			};
			amiralizadeh9480.laravel-extra-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "amiralizadeh9480";
					name = "laravel-extra-intellisense";
					version = "0.6.2";
					sha256 = "0dpyizygiy8pk3ys29sckpzhmpykj93gqrrbg2wr8s1k4mvx75vd";
				};
			};
			kokororin.vscode-phpfmt = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kokororin";
					name = "vscode-phpfmt";
					version = "1.0.31";
					sha256 = "0iqsikqyja1jg4r8p7n5hx7g3cdidij2gnllqs8ivbx0gvkxdhn0";
				};
			};
			ms-azuretools.vscode-azurestorage = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azurestorage";
					version = "0.14.2";
					sha256 = "0rxfbly22z29ra6nk6llh96bk0x9bs58jx027s04p17lhsn4m4nv";
				};
			};
			wcwhitehead.bootstrap-3-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wcwhitehead";
					name = "bootstrap-3-snippets";
					version = "0.1.0";
					sha256 = "09pyr8y7ai2zyqfkwgnphi0gm2ag0phphcmgrh892gdy1y0ckx5z";
				};
			};
			Sophisticode.php-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Sophisticode";
					name = "php-formatter";
					version = "0.2.4";
					sha256 = "10xj50mf3ismglv52nvxql2197gxngw0h3apm5rgd4kkfzadk9qx";
				};
			};
			ms-azure-devops.azure-pipelines = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azure-devops";
					name = "azure-pipelines";
					version = "1.205.0";
					sha256 = "03i6sdgb971xcww272l00061b8zgiqww7y7w2fgizmb7m3f9s9rr";
				};
			};
			akamud.vscode-theme-onelight = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "akamud";
					name = "vscode-theme-onelight";
					version = "2.2.3";
					sha256 = "1mzd77sv6lb6kfv5fvdvzggs488q553cf752byrml981ys9r7khz";
				};
			};
			rust-lang.rust-analyzer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rust-lang";
					name = "rust-analyzer";
					version = "0.4.1119";
					sha256 = "0lsb1cd8j1m1632gsjj2h51j5g2gfc1d1h0jkj028qpl5nikbbxx";
				};
			};
			tushortz.python-extended-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tushortz";
					name = "python-extended-snippets";
					version = "0.0.1";
					sha256 = "12w80d43ipwd0vwqp0frnws9yvda03yc3g54ggm60q85x01x3fmc";
				};
			};
			bierner.markdown-preview-github-styles = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "markdown-preview-github-styles";
					version = "1.0.1";
					sha256 = "1bjx46v17d18c9bplz70dx6fpsc6pr371ihpawhlr1y61b59n5aj";
				};
			};
			natewallace.angular2-inline = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "natewallace";
					name = "angular2-inline";
					version = "0.0.17";
					sha256 = "1yi64g78qpwri54yf7172himi14sw3czyxbh93ccc9zjlw30r7ry";
				};
			};
			johnstoncode.svn-scm = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnstoncode";
					name = "svn-scm";
					version = "2.15.5";
					sha256 = "1c7xaq1x6iz2lqpajdnv2dhmgchwl8fnx367v8blbdbf4kjrdbbf";
				};
			};
			castwide.solargraph = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "castwide";
					name = "solargraph";
					version = "0.23.0";
					sha256 = "0ivawyq16712j2q4wic3y42lbqfml5gs24glvlglpi0kcgnii96n";
				};
			};
			AmazonWebServices.aws-toolkit-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AmazonWebServices";
					name = "aws-toolkit-vscode";
					version = "1.45.0";
					sha256 = "1q05bgr7pv14bsvhjr133bnmc81nskgyzvqnr6j66c3qr0hqinr5";
				};
			};
			eriklynd.json-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eriklynd";
					name = "json-tools";
					version = "1.0.2";
					sha256 = "0g5ppkc0rpqaprb3l0dsdkzcgmb24apjrq88bw77qll2ra2n7l7f";
				};
			};
			mathiasfrohlich.Kotlin = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mathiasfrohlich";
					name = "Kotlin";
					version = "1.7.1";
					sha256 = "0zi8s1y9l7sfgxfl26vqqqylsdsvn5v2xb3x8pcc4q0xlxgjbq1j";
				};
			};
			FallenMax.mithril-emmet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "FallenMax";
					name = "mithril-emmet";
					version = "0.7.7";
					sha256 = "0k07hxbskxax0x006chdncfy0w8c2r47pnn80n29xirbic5nhn5b";
				};
			};
			ms-toolsai.vscode-ai = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-toolsai";
					name = "vscode-ai";
					version = "0.13.2022070809";
					sha256 = "06wxnbqjk6ky4phx4i23q65c7rzx13z83cfc72kk82yhdls79g2g";
				};
			};
			ms-mssql.sql-bindings-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-mssql";
					name = "sql-bindings-vscode";
					version = "0.2.0";
					sha256 = "02zjy5z2a6vmzx7vlxz5gk9sqk753yy16qlpv18mkdpf1371wlya";
				};
			};
			mrcrowl.easy-less = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrcrowl";
					name = "easy-less";
					version = "1.7.3";
					sha256 = "1hf2x60xgi68jxbbwfg10xq44ijns5z18z99l7wgyfj36zgb7nmn";
				};
			};
			WakaTime.vscode-wakatime = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "WakaTime";
					name = "vscode-wakatime";
					version = "18.1.6";
					sha256 = "15ldc9774jgwqlw5qfrdmpmgdyvps2rkn2lh7v2f0w457x9h52lx";
				};
			};
			rvest.vs-code-prettier-eslint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rvest";
					name = "vs-code-prettier-eslint";
					version = "5.0.3";
					sha256 = "1bk7kcgs0afy8k1wrkdqwjwmgl0ndswd0h7qx61jhiad76q9iq4k";
				};
			};
			waderyan.nodejs-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "waderyan";
					name = "nodejs-extension-pack";
					version = "0.1.9";
					sha256 = "0vr9q7dglm66nykb121zbhf6kq8w9kxh0647ya8i4m9pz47h9yrz";
				};
			};
			junstyle.php-cs-fixer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "junstyle";
					name = "php-cs-fixer";
					version = "0.3.1";
					sha256 = "0lq976sgb6gvjjwbfj303yxs7rvmjz42l8ksijk41xl8n10har4j";
				};
			};
			liviuschera.noctis = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "liviuschera";
					name = "noctis";
					version = "10.40.0";
					sha256 = "1ry0vkyb92c6p6i8dpjq7sihvbpl45gngb8fym22nylmnfi9dcai";
				};
			};
			cyrilletuzi.angular-schematics = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cyrilletuzi";
					name = "angular-schematics";
					version = "5.2.3";
					sha256 = "1h2gppcf2kvr1gp0rlg9x35xpb7pfbhjnsnadc9bf3yvfad26dsj";
				};
			};
			bajdzis.vscode-database = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bajdzis";
					name = "vscode-database";
					version = "2.2.3";
					sha256 = "1qb285q8kc8hiraz42g9xsl95w9jginfl1rahj9hvx010pvrvz3p";
				};
			};
			humy2833.ftp-simple = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "humy2833";
					name = "ftp-simple";
					version = "0.7.6";
					sha256 = "0pq4hjqyay7pj6pap09vgf3j6kpi4hpncgzi1y8w04fpin4cdaaf";
				};
			};
			janisdd.vscode-edit-csv = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "janisdd";
					name = "vscode-edit-csv";
					version = "0.7.1";
					sha256 = "0xnd110lc3gc7nxin9ig69n7dsh72yx9r96fxyxb3pmlkxbqzqi1";
				};
			};
			ms-vscode.js-debug-nightly = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "js-debug-nightly";
					version = "2022.7.617";
					sha256 = "1ycay8sya568im60bxnxcp5hmz4wwwvjzxchwqiz9z0na6m2vynv";
				};
			};
			bierner.color-info = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "color-info";
					version = "0.7.0";
					sha256 = "0gxjsgnbbsfvxj6yk4ln95fsrn9y0nhw0h5s7nsl866pj7if7bp0";
				};
			};
			tinkertrain.theme-panda = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tinkertrain";
					name = "theme-panda";
					version = "1.3.0";
					sha256 = "1p2jvm4w624d14bq22jglds2b68swysqkb2xhh1ph55ppjhrfcwa";
				};
			};
			arcticicestudio.nord-visual-studio-code = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "arcticicestudio";
					name = "nord-visual-studio-code";
					version = "0.19.0";
					sha256 = "05bmzrmkw9syv2wxqlfddc3phjads6ql2grknws85fcqzqbfl1kb";
				};
			};
			auchenberg.vscode-browser-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "auchenberg";
					name = "vscode-browser-preview";
					version = "0.7.2";
					sha256 = "02bflapvzgdj2xqpnlanl229wlnnzp33s4mkxpwc9q13xslf2j69";
				};
			};
			LittleFoxTeam.vscode-python-test-adapter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "LittleFoxTeam";
					name = "vscode-python-test-adapter";
					version = "0.7.1";
					sha256 = "1sjbi8k4yahrs7gkgj4x7ykwfcbzia3z4j6slc7izvnl6m0n0way";
				};
			};
			GitLab.gitlab-workflow = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GitLab";
					name = "gitlab-workflow";
					version = "3.47.2";
					sha256 = "1nzaj7sxhbr3hliy7pixhy3xv5pjhha0yix67pa82d6syz5ggqjm";
				};
			};
			Wscats.eno = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Wscats";
					name = "eno";
					version = "2.3.53";
					sha256 = "0mfqq3gz2f5clmqlrvlf3qqvx7ssjayvqdmb2r7gfqxj9jz9gc2c";
				};
			};
			justusadam.language-haskell = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "justusadam";
					name = "language-haskell";
					version = "3.6.0";
					sha256 = "115y86w6n2bi33g1xh6ipz92jz5797d3d00mr4k8dv5fz76d35dd";
				};
			};
			hoovercj.vscode-power-mode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hoovercj";
					name = "vscode-power-mode";
					version = "3.0.2";
					sha256 = "0r5s7ks50qxzv85qqxgnb2b0ck8vi7zzd2vmwbmjrhr6mnb86kv4";
				};
			};
			salesforce.salesforce-vscode-slds = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforce-vscode-slds";
					version = "1.4.8";
					sha256 = "1dxdamgbgrp5vv20xihsyqa6dnmpjqxwsij2d5gjm3d76yz6zv39";
				};
			};
			infinity1207.angular2-switcher = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "infinity1207";
					name = "angular2-switcher";
					version = "0.4.0";
					sha256 = "1mmzf9hnrz1qb8307kgry3yvqjpw79fzn6km6wf8bj81y0gv4d45";
				};
			};
			DigitalBrainstem.javascript-ejs-support = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DigitalBrainstem";
					name = "javascript-ejs-support";
					version = "1.3.1";
					sha256 = "0dgf6cyqd3jhwr9apxyzkmr2x3a3nr1xbq2glh0y88y8p4j51d29";
				};
			};
			REditorSupport.r = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "REditorSupport";
					name = "r";
					version = "2.5.0";
					sha256 = "1w9rq85ld9dc47vyhga6581l86h2vi0bqzzl8cq8bn1z64q5yiiq";
				};
			};
			jprestidge.theme-material-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jprestidge";
					name = "theme-material-theme";
					version = "1.0.1";
					sha256 = "0w04zz5ryj1nj1zi3r77sws6q1vfbw0v6h30vqib7zszcs8fqj4x";
				};
			};
			spywhere.guides = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "spywhere";
					name = "guides";
					version = "0.9.3";
					sha256 = "1kvsj085w1xax6fg0kvsj1cizqh86i0pkzpwi0sbfvmcq21i6ghn";
				};
			};
			pmneo.tsimporter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pmneo";
					name = "tsimporter";
					version = "2.0.1";
					sha256 = "124jyk9iz3spq8q17z79lqgcwfabbvldcq243xbzbjmbb01ds3i5";
				};
			};
			peakchen90.vue-beautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "peakchen90";
					name = "vue-beautify";
					version = "2.0.4";
					sha256 = "18jlplqyszysmzmd7qy6qyi6z1vgxbyrg9fxn1y2s9dcilnzc9dr";
				};
			};
			cweijan.vscode-mysql-client2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cweijan";
					name = "vscode-mysql-client2";
					version = "5.5.5";
					sha256 = "0bd80bwjqp5b42k018xz0b39qaawl2lf8xl563w8n4dqizjmyr9r";
				};
			};
			whatwedo.twig = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "whatwedo";
					name = "twig";
					version = "1.0.2";
					sha256 = "0d552g0g9c5pmak4b9kjqr6z4rah276xs45lijv1hrs04jfwl8pr";
				};
			};
			negokaz.live-server-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "negokaz";
					name = "live-server-preview";
					version = "0.1.4";
					sha256 = "0xmrpjlws0wq4b8gh4x17mwx17s2fxdqhj86wmgmxxkpfcl7pc0h";
				};
			};
			donjayamanne.javadebugger = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "donjayamanne";
					name = "javadebugger";
					version = "0.1.5";
					sha256 = "0p441by06ys2q8vihw8wg1l5p90ssxap8nqazl48n9x0d7dzij8c";
				};
			};
			stringham.move-ts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "stringham";
					name = "move-ts";
					version = "1.12.0";
					sha256 = "19yxria6z88y5xq4v4y4mlaxlg7y7463k0cqq8c8skvn8k49sfma";
				};
			};
			IBM.output-colorizer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "IBM";
					name = "output-colorizer";
					version = "0.1.2";
					sha256 = "0i9kpnlk3naycc7k8gmcxas3s06d67wxr3nnyv5hxmsnsx5sfvb7";
				};
			};
			alexisvt.flutter-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alexisvt";
					name = "flutter-snippets";
					version = "3.0.0";
					sha256 = "1vq4xpzdkk0bima5mx4nzxrfcqf168pm9wj0xi50lpv24vw4db24";
				};
			};
			ms-vscode.vscode-node-azure-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "vscode-node-azure-pack";
					version = "1.0.0";
					sha256 = "0bj3djqh8l1zb2i4mwb3qhb6kvnazzal5217v3s8w2iv71gcn5i7";
				};
			};
			kumar-harsh.graphql-for-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kumar-harsh";
					name = "graphql-for-vscode";
					version = "1.15.3";
					sha256 = "1x4vwl4sdgxq8frh8fbyxj5ck14cjwslhb0k2kfp6hdfvbmpw2fh";
				};
			};
			LeetCode.vscode-leetcode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "LeetCode";
					name = "vscode-leetcode";
					version = "0.18.1";
					sha256 = "04qk84zikpq80h2pbby8v3rrdx1nyssmscmd4rfvxlfbv65lcvv2";
				};
			};
			flowtype.flow-for-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "flowtype";
					name = "flow-for-vscode";
					version = "2.1.0";
					sha256 = "050wrjicwsn5ky490rpqnlq5m7q3y1h6k4ckrivxxpwmy8scfiak";
				};
			};
			alphabotsec.vscode-eclipse-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alphabotsec";
					name = "vscode-eclipse-keybindings";
					version = "0.16.1";
					sha256 = "1yjgybgvjlgpw8g9n83llpmf2nvfpg81s7x7ml3rp97gnx5hxbjl";
				};
			};
			vscjava.vscode-lombok = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-lombok";
					version = "1.0.1";
					sha256 = "1hc7p7an3yd2ssq1laixr0z8cn9yz7aq25hdw6k2fakgklzis6y6";
				};
			};
			utsavm9.c-cpp-flag-debugging = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "utsavm9";
					name = "c-cpp-flag-debugging";
					version = "0.0.1";
					sha256 = "0irhpa29lq4bcjnlanbbjn6hah1258fqgsr4n93b7fzwar6avjpx";
				};
			};
			ryu1kn.partial-diff = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ryu1kn";
					name = "partial-diff";
					version = "1.4.3";
					sha256 = "0x3lkvna4dagr7s99yykji3x517cxk5kp7ydmqa6jb4bzzsv1s6h";
				};
			};
			ms-vsonline.vsonline = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vsonline";
					name = "vsonline";
					version = "1.0.3076";
					sha256 = "0bzkqkwihjnh96hv29zy6r5xb42vvrrp0wmgn6qqfmxnq6w9hhci";
				};
			};
			kisstkondoros.vscode-codemetrics = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kisstkondoros";
					name = "vscode-codemetrics";
					version = "1.24.0";
					sha256 = "1rgq72masgb29mbv69zf82calwyqnkask3w6qa2cdjhf3lkahd4x";
				};
			};
			enkia.tokyo-night = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "enkia";
					name = "tokyo-night";
					version = "0.8.9";
					sha256 = "0lliwwikrirq1zv8bxsb0k83j293h8h3sd6qrhcjwzjg08ir9mb9";
				};
			};
			ms-vscode.makefile-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "makefile-tools";
					version = "0.5.0";
					sha256 = "18p0ayw20f2shsw7fysvdrh1mc9fyp1cjiv7xmh5yxda7q3h05m0";
				};
			};
			karigari.chat = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "karigari";
					name = "chat";
					version = "0.35.0";
					sha256 = "1wnbzsyycggmn1pikfk9clzlnmg0dx7zy5y50smra74c3wnp2x9x";
				};
			};
			alexiv.vscode-angular2-files = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alexiv";
					name = "vscode-angular2-files";
					version = "1.6.4";
					sha256 = "0qj20ky9kv9plja4hlivz1ycsqfnzmwyxak9n2z52z08m5yqz612";
				};
			};
			slevesque.shader = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "slevesque";
					name = "shader";
					version = "1.1.5";
					sha256 = "14yraymi96f6lpcrwk93llbiraq8gqzk7jzyw7xmndhcwhazpz9x";
				};
			};
			ms-vscode-remote.remote-ssh-explorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-ssh-explorer";
					version = "0.56.0";
					sha256 = "1gwnyzn37xh7aidig3pk7mq7mlx9hbvw3zbgjp3llqap6xrfxcs3";
				};
			};
			sysoev.language-stylus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sysoev";
					name = "language-stylus";
					version = "1.16.0";
					sha256 = "1abp57j804m5c1lr7x3x5kxa1g19cj3dxbjlpjg2lhhplb7jav7m";
				};
			};
			alexkrechik.cucumberautocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alexkrechik";
					name = "cucumberautocomplete";
					version = "2.15.2";
					sha256 = "1kaxvszpj5cami7k52ddzd9fc108pzz1ga5hhi78b468azplkl1i";
				};
			};
			adashen.vscode-tomcat = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adashen";
					name = "vscode-tomcat";
					version = "0.12.1";
					sha256 = "0vgs7viglkmw71717m1sbwaqgxx5v4cmny1vahqpq5ji0y42sh1b";
				};
			};
			ms-vscode.live-server = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "live-server";
					version = "0.2.12";
					sha256 = "0i5hc1l91jnl96whdpx21bsfivw45gkzif2zj19rczy5xvr77cz2";
				};
			};
			onecentlin.laravel-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "onecentlin";
					name = "laravel-extension-pack";
					version = "1.1.0";
					sha256 = "1r8kzqy7dsgi0bkkjc35kjn68iibg43xk9v0ycm48sxjdf2c6alx";
				};
			};
			ms-toolsai.vscode-ai-remote = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-toolsai";
					name = "vscode-ai-remote";
					version = "0.13.2022070809";
					sha256 = "0lplyy4w3zsm74n3y5yjfvy2d38l7f2qjlqii2s728fbvf0jvsgs";
				};
			};
			akamud.vscode-javascript-snippet-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "akamud";
					name = "vscode-javascript-snippet-pack";
					version = "0.1.6";
					sha256 = "0qq4ckld3bx0i33ifhq2ijcjiv6ljd6b0f2rlisjb38d14w5n73v";
				};
			};
			Ionide.Ionide-fsharp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Ionide";
					name = "Ionide-fsharp";
					version = "6.0.6";
					sha256 = "1x2v1k10a58n3lh7mszwmgj9pqhlisa88mrbrykmabrsai1sy1c9";
				};
			};
			bibhasdn.django-html = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bibhasdn";
					name = "django-html";
					version = "1.3.0";
					sha256 = "0aal41g2yk05vd9l67ig80p0qp18nhv92smrsyymxhp6r1alj5gg";
				};
			};
			jorgeserrano.vscode-csharp-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jorgeserrano";
					name = "vscode-csharp-snippets";
					version = "1.1.0";
					sha256 = "1wsrbana07bcy6jslk8mpxzx53b9mnf4f8g9srwfkcbqhw2p322x";
				};
			};
			Tyriar.sort-lines = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tyriar";
					name = "sort-lines";
					version = "1.9.1";
					sha256 = "0dds99j6awdxb0ipm15g543a5b6f0hr00q9rz961n0zkyawgdlcb";
				};
			};
			Zaczero.bootstrap-v4-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Zaczero";
					name = "bootstrap-v4-snippets";
					version = "1.1.3";
					sha256 = "0cz8g3m6ixs13hd6fqhpwf7d7ma78wm5gknh0dpll51iv6d1rd8x";
				};
			};
			jock.svg = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jock";
					name = "svg";
					version = "1.4.18";
					sha256 = "09mximd6c843nclk8yi6brg3kkpyxz96ln0mnmgplw34lfqwm0rh";
				};
			};
			xyz.local-history = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xyz";
					name = "local-history";
					version = "1.8.1";
					sha256 = "1mfmnbdv76nvwg4xs3rgsqbxk8hw9zr1b61har9c3pbk9r4cay7v";
				};
			};
			ChakrounAnas.turbo-console-log = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ChakrounAnas";
					name = "turbo-console-log";
					version = "2.3.2";
					sha256 = "1gxwkwm3fzbgivs1s963dgppwdhyhmvn3yh18hpyphmr0y621nsx";
				};
			};
			webfreak.debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "webfreak";
					name = "debug";
					version = "0.26.0";
					sha256 = "0rsxnjcs4imd3kj01g2k92xv4vr48rs0zb6x9jcg7vr64yry0nk4";
				};
			};
			EliverLara.andromeda = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "EliverLara";
					name = "andromeda";
					version = "1.7.1";
					sha256 = "1ijpbdpas933r2438m5yn9d87wcp9rxx5kly93p20c02hgvlnal0";
				};
			};
			dariofuzinato.vue-peek = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dariofuzinato";
					name = "vue-peek";
					version = "1.0.2";
					sha256 = "1dvjva289kwvf6ijhz4am4bpp3961r7f9x2a9ng66m76icwab7jl";
				};
			};
			stef-k.laravel-goto-controller = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "stef-k";
					name = "laravel-goto-controller";
					version = "0.0.15";
					sha256 = "0kf1agxnzd82846wakg83i8pisrh61hbnvd5s2n5wv2lgszxz6rc";
				};
			};
			ms-azuretools.vscode-azurevirtualmachines = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azurevirtualmachines";
					version = "0.6.2";
					sha256 = "11fsw559xi15a7hch5vcx3985dhb9c797dfbq3jcmm08q6frw83h";
				};
			};
			sumneko.lua = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sumneko";
					name = "lua";
					version = "3.4.2";
					sha256 = "0xxhjzfng51xknhwrjzxllgywdh46v6w6d4kpn0aspj1jzjnk9fp";
				};
			};
			adpyke.vscode-sql-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adpyke";
					name = "vscode-sql-formatter";
					version = "1.4.4";
					sha256 = "06q78hnq76mdkhsfpym2w23wg9wcpikpfgz07mxk1vnm9h3jm2l3";
				};
			};
			mohd-akram.vscode-html-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mohd-akram";
					name = "vscode-html-format";
					version = "0.0.4";
					sha256 = "0vgvc3hnhnxa3kza5n42m2wzy4q30pcfhawjxhv26f3igpr32h8k";
				};
			};
			Leopotam.csharpfixformat = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Leopotam";
					name = "csharpfixformat";
					version = "0.0.84";
					sha256 = "1z6y23rlam4cnnyzfvd3hihx5k5v8d7243qivvr1ks5z1yl5whb5";
				};
			};
			fknop.vscode-npm = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fknop";
					name = "vscode-npm";
					version = "3.3.0";
					sha256 = "0v97whq3dpd5if01n0b7zxb7n23ljyq8ay4px8bvqqc2cpiy353w";
				};
			};
			almenon.arepl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "almenon";
					name = "arepl";
					version = "2.0.3";
					sha256 = "1d3iwcw5ac7nd3m2cxj4v86v1scxkg3zdxyiyrmmmpr2jnlav295";
				};
			};
			scala-lang.scala = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "scala-lang";
					name = "scala";
					version = "0.5.5";
					sha256 = "1gqgamm97sq09za8iyb06jf7hpqa2mlkycbx6zpqwvlwd3a92qr1";
				};
			};
			misogi.ruby-rubocop = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "misogi";
					name = "ruby-rubocop";
					version = "0.8.6";
					sha256 = "0hpmfja2q95fx2j7w0lb2nfi1v7dka29q0whfabj065bwz60j67a";
				};
			};
			be5invis.vscode-custom-css = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "be5invis";
					name = "vscode-custom-css";
					version = "6.0.2";
					sha256 = "0zxbb0l6h109v98ixkbwmnzybxlfakl8a708yxc9lcgdjy032z94";
				};
			};
			firsttris.vscode-jest-runner = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "firsttris";
					name = "vscode-jest-runner";
					version = "0.4.48";
					sha256 = "0x6f8adr1c8yfyj7hwjdkx501phpxqcz6k26d9c1f8jbjpi4vwvg";
				};
			};
			skyran.js-jsx-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "skyran";
					name = "js-jsx-snippets";
					version = "11.0.0";
					sha256 = "1g6xdi7d7jsqvjvzxifi1rp2k2avp87w64kyiipnrh480xjznf9q";
				};
			};
			adpyke.codesnap = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adpyke";
					name = "codesnap";
					version = "1.3.4";
					sha256 = "012sj4a65sr8014z4zpxqzb6bkj7pnhm4rls73xpwawk6hwal7km";
				};
			};
			MS-CEINTL.vscode-language-pack-it = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-it";
					version = "1.69.7060951";
					sha256 = "06rgy6x3i2422dv6spacdzpl36gsxv7rwrs02assa5pspllyc9jq";
				};
			};
			formulahendry.dotnet-test-explorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "dotnet-test-explorer";
					version = "0.7.7";
					sha256 = "0h8lhsz993wzy4am0dgb0318mfrc5isywcxi0k4nakzj0dkk3w6y";
				};
			};
			lihui.vs-color-picker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lihui";
					name = "vs-color-picker";
					version = "1.0.0";
					sha256 = "08rq13ai1bjzmfmxlmsfqnh856q521y4kjhbf2031b8h73ya5jdd";
				};
			};
			GoogleCloudTools.cloudcode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GoogleCloudTools";
					name = "cloudcode";
					version = "1.19.0";
					sha256 = "1kdb4ib74pwzy7r9l7ri6zjkbbzwrq0iqv72pgwwsikbap3p78va";
				};
			};
			ms-inkling.ms-inkling = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-inkling";
					name = "ms-inkling";
					version = "1.0.40";
					sha256 = "1s1h6hfyg3bc52vcg916pzncrd5dfcs40zibab1j8vkfl56qv9gk";
				};
			};
			rogalmic.bash-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rogalmic";
					name = "bash-debug";
					version = "0.3.9";
					sha256 = "0n7lyl8gxrpc26scffbrfczdj0n9bcil9z83m4kzmz7k5dj59hbz";
				};
			};
			bencoleman.armview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bencoleman";
					name = "armview";
					version = "0.4.6";
					sha256 = "0ymq7zpjp2f5b3ms3mi6qjb4gc2za1w7dz881czka17br0x697xx";
				};
			};
			qiu8310.minapp-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "qiu8310";
					name = "minapp-vscode";
					version = "2.4.8";
					sha256 = "07dkyvfb2xc6yxd6nphj1h6civ0zwj6ckq2gj9w17486biljn0n4";
				};
			};
			jolaleye.horizon-theme-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jolaleye";
					name = "horizon-theme-vscode";
					version = "2.0.2";
					sha256 = "1ch8m9h6zxn8xj92ml5294637ygabnyird3f6vbh1djzwwz5rykc";
				};
			};
			mutantdino.resourcemonitor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mutantdino";
					name = "resourcemonitor";
					version = "1.0.7";
					sha256 = "03dqa381qcx07xhwis5ja8scskxl61shj7ax945ajydynyr7a66g";
				};
			};
			danwahlin.angular2-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "danwahlin";
					name = "angular2-snippets";
					version = "1.0.22";
					sha256 = "0nm9kvyjh06qm961ld26iqhdlzsd0hf1am1x4qw27v7jq66yqq6h";
				};
			};
			SolarLiner.linux-themes = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SolarLiner";
					name = "linux-themes";
					version = "1.0.1";
					sha256 = "035gxrny602cxi21jwbaill2grvqmy0lsm539ipgn4zvyakm0pcs";
				};
			};
			mgesbert.python-path = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mgesbert";
					name = "python-path";
					version = "0.0.11";
					sha256 = "06m2daywn234maicm4p9w1kz58d61fkvqjvcybkglkj91japj7mn";
				};
			};
			_4ops.terraform = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "4ops";
					name = "terraform";
					version = "0.2.5";
					sha256 = "0ciagyhxcxikfcvwi55bhj0gkg9p7p41na6imxid2mxw2a7yb4nb";
				};
			};
			_13xforever.language-x86-64-assembly = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "13xforever";
					name = "language-x86-64-assembly";
					version = "3.0.0";
					sha256 = "0lxg58hgdl4d96yjgrcy2dbacxsc3wz4navz23xaxcx1bgl1i2y0";
				};
			};
			ms-vscode.vs-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "vs-keybindings";
					version = "0.2.1";
					sha256 = "1h7dihd6f39jcp27haiwbjdsymyi5p2v4f101lxdi5fafz3y6win";
				};
			};
			Tyriar.lorem-ipsum = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tyriar";
					name = "lorem-ipsum";
					version = "1.3.1";
					sha256 = "16crr9wci9cxf0mpap1pkpcnvk2qm3amp9zsrf891cyknb59w4w8";
				};
			};
			chenxsan.vscode-standardjs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "chenxsan";
					name = "vscode-standardjs";
					version = "1.4.1";
					sha256 = "0hiaqflp0d3k2pq3p44wrpyn4v6n0x660f4v47nf9bsdn5lidih3";
				};
			};
			kamikillerto.vscode-colorize = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kamikillerto";
					name = "vscode-colorize";
					version = "0.11.1";
					sha256 = "1h82b1jz86k2qznprng5066afinkrd7j3738a56idqr3vvvqnbsm";
				};
			};
			shufo.vscode-blade-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shufo";
					name = "vscode-blade-formatter";
					version = "0.16.2";
					sha256 = "0jycsa8g2rccb1qswjr0m38ac8gl0pvqbswvry3b2rlkh18d99qd";
				};
			};
			rokoroku.vscode-theme-darcula = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rokoroku";
					name = "vscode-theme-darcula";
					version = "1.2.3";
					sha256 = "10dz5xhmxlw8qayhp3hj8sf57m9sx10sqlz59inqygl37kf3wlmn";
				};
			};
			fisheva.eva-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fisheva";
					name = "eva-theme";
					version = "1.8.7";
					sha256 = "1780ca9wan6vsiazkkxcmv8drln5gkd4wm49jz9di7bizxvzryw2";
				};
			};
			mongodb.mongodb-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mongodb";
					name = "mongodb-vscode";
					version = "0.9.3";
					sha256 = "0ncz14bgvw4lkbmdqg537xp5js90k7ys0wa9dbgjgqqi1l1flklh";
				};
			};
			coderfee.open-html-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "coderfee";
					name = "open-html-in-browser";
					version = "0.1.21";
					sha256 = "05fdn7k24s2x8dx6iv73ghngz0165m44cxiz31msb70rnjghbb4c";
				};
			};
			Gimly81.matlab = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Gimly81";
					name = "matlab";
					version = "2.3.1";
					sha256 = "06zb2mqabcck1ij8d6g02x5yz8r995rblig2dydzpilzswppkz6j";
				};
			};
			ms-azuretools.vscode-bicep = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-bicep";
					version = "0.8.9";
					sha256 = "03j5im9hv80bmllvgsf2dqazgi3vfm3n1y2kr92lknap08bbknfr";
				};
			};
			ms-vscode.mono-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "mono-debug";
					version = "0.16.2";
					sha256 = "10hixqkw5r3cg52xkbky395lv72sb9d9wrngdvmrwx62hkbk5465";
				};
			};
			fabianlauer.vs-code-xml-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fabianlauer";
					name = "vs-code-xml-format";
					version = "0.1.5";
					sha256 = "0nvzvib1443mcbskd1xg8m3gypvdb7jqqy90nnf97pgmmrywvv07";
				};
			};
			geyao.html-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "geyao";
					name = "html-snippets";
					version = "0.2.3";
					sha256 = "0zh3zsirv7vmd76laslam55d7f3bvxmw16wyz9aqs6r51z5j82rh";
				};
			};
			sleistner.vscode-fileutils = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sleistner";
					name = "vscode-fileutils";
					version = "3.5.0";
					sha256 = "1yjn1fah12r3i1dhib58czcwb6zl3i6kfmsi65a5984df7r1lnxs";
				};
			};
			svelte.svelte-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "svelte";
					name = "svelte-vscode";
					version = "105.18.1";
					sha256 = "0fa9k4j73n76fx06xr6003pn7mfapvpjjqddl5pn9i02m5q975aj";
				};
			};
			formulahendry.docker-explorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "docker-explorer";
					version = "0.1.7";
					sha256 = "02hi47by918p08kfbbs3m3v95mv3kd18wh35l507ibssjyy41jgr";
				};
			};
			huizhou.githd = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "huizhou";
					name = "githd";
					version = "2.2.4";
					sha256 = "09l7254vkz5ab8yr9dirgm606llwxhfnv1p29l58m9jgi8mdm7hl";
				};
			};
			mkxml.vscode-filesize = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mkxml";
					name = "vscode-filesize";
					version = "3.1.0";
					sha256 = "1zxdsqr5h0xl6arphi5i1xfgby4cin39jxpnmdgcg41p6qr3k3z7";
				};
			};
			salesforce.salesforcedx-vscode-soql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "salesforce";
					name = "salesforcedx-vscode-soql";
					version = "55.4.0";
					sha256 = "0kc363fa620w9p9v1f83a9zfafh5qvqcdpp5bvjxmk9rg0213k5w";
				};
			};
			lextudio.restructuredtext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lextudio";
					name = "restructuredtext";
					version = "190.1.4";
					sha256 = "1y25b2i16xjb1cbmkxd822jh10jdclk3h16hf62s65l00z69gfxv";
				};
			};
			chrmarti.regex = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "chrmarti";
					name = "regex";
					version = "0.4.0";
					sha256 = "0krmwwgi5wai5mx3jh45kdv8mblnn71cygasxh3rh0l86in9686p";
				};
			};
			shalldie.background = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shalldie";
					name = "background";
					version = "1.1.31";
					sha256 = "1r6qrxyrlm6f1hhhvn8xakw43mcwhvj91qs4yqz0qxmyicqqp66n";
				};
			};
			samuelcolvin.jinjahtml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "samuelcolvin";
					name = "jinjahtml";
					version = "0.17.0";
					sha256 = "120z8barzgva0sr1g7xj4arpjz96v4zxh2zgk56jzdgnafzyq71b";
				};
			};
			bierner.markdown-mermaid = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "markdown-mermaid";
					version = "1.14.2";
					sha256 = "0lfl53khp8zhyh8ncdbbxjm7yg61zvm2wrkdhv5nk2kpcxiq1725";
				};
			};
			ajshort.include-autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ajshort";
					name = "include-autocomplete";
					version = "0.0.4";
					sha256 = "0kmsvc29hhzpzhchmy0qmh2v364hvhaiq5zp6gg8v0ys67xjxiza";
				};
			};
			msjsdiag.cordova-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "msjsdiag";
					name = "cordova-tools";
					version = "2.4.1";
					sha256 = "0b3qncnsjbrsqsbzpjhc5776a0h0w1k30bjb0ih3d9r4r4zzp50x";
				};
			};
			wwm.better-align = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wwm";
					name = "better-align";
					version = "1.1.6";
					sha256 = "1ldvpava9xlqy3zwwc0c04pk9dh09jwcwz5lk3b2cr1z8bxn54lh";
				};
			};
			himanoa.Python-autopep8 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "himanoa";
					name = "Python-autopep8";
					version = "1.0.2";
					sha256 = "0603chp05sfx6b5r0cll6xbx9f4ki2ckbwbs71vizdnahfnbbckj";
				};
			};
			miramac.vscode-exec-node = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "miramac";
					name = "vscode-exec-node";
					version = "0.5.4";
					sha256 = "16jsmfi7js4qhn318kgyc021mvkfcgrc0smjval8nl6whb92k6ay";
				};
			};
			bianxianyang.htmlplay = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bianxianyang";
					name = "htmlplay";
					version = "0.0.10";
					sha256 = "1fz58jqkfg1lr8vwrmscg724r399bfxvkyf4k5kpx38zl7ndcgli";
				};
			};
			remimarsal.prettier-now = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "remimarsal";
					name = "prettier-now";
					version = "1.4.9";
					sha256 = "1aqm0dmiav59kn57gv6rhs9izy5nnpvjmriy3sv2sjjjv8ypbpr1";
				};
			};
			mrmlnc.vscode-apache = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-apache";
					version = "1.2.0";
					sha256 = "16xzh8bzry64967x7q04jv0bp4cjgcjq7wwp8158rvfpi6nn0z61";
				};
			};
			slevesque.vscode-hexdump = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "slevesque";
					name = "vscode-hexdump";
					version = "1.8.1";
					sha256 = "1bw1n4n51kvd10v191pfnrbb99mm8is08qa6qniypl4c31fx3lq4";
				};
			};
			oysun.vuehelper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oysun";
					name = "vuehelper";
					version = "0.1.0";
					sha256 = "04r1xxzcscm2fqn6g7ci3gqhrym0l8ajm0mnxrw045ch5xa6rmzx";
				};
			};
			liuji-jim.vue = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "liuji-jim";
					name = "vue";
					version = "0.1.5";
					sha256 = "16bnx0rg9vbp0f3zhxkkalczsvvplqlxb2hn7yprrbspz3jjlbjj";
				};
			};
			naco-siren.gradle-language = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "naco-siren";
					name = "gradle-language";
					version = "0.2.3";
					sha256 = "15lzxvym0mkljjn57av1p4z6hqqwbsbn5idw2fn7nccgrl93aywf";
				};
			};
			fwcd.kotlin = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fwcd";
					name = "kotlin";
					version = "0.2.26";
					sha256 = "1br0vr4v1xcl4c7bcqwzfqd4xr6q2ajwkipqrwm928mj96dkafkn";
				};
			};
			timonwong.shellcheck = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "timonwong";
					name = "shellcheck";
					version = "0.19.5";
					sha256 = "1v6z0qzcqhb458pf6dwx35xk2iw3j3swx8dhys4qpzi3cpqvd6p1";
				};
			};
			mshr-h.VerilogHDL = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mshr-h";
					name = "VerilogHDL";
					version = "1.5.4";
					sha256 = "1i8qcfx5v4d30gkyy00a4d8l6ss828va6lp69h9i1ynrgqzl85av";
				};
			};
			miguelsolorio.fluent-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "miguelsolorio";
					name = "fluent-icons";
					version = "0.0.17";
					sha256 = "00319xdzl5cwa2kgwb30dlaznkc6cs51sb69s0zak40r78pls0hd";
				};
			};
			bradgashler.htmltagwrap = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bradgashler";
					name = "htmltagwrap";
					version = "0.0.7";
					sha256 = "0l511z13idv7c3i6yj6yzqcwds506bdzbxgmjcq24z5y2nii8420";
				};
			};
			jundat95.react-native-snippet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jundat95";
					name = "react-native-snippet";
					version = "0.5.6";
					sha256 = "0qcrc0kg8c7wzgn4r37silhgrm7i7i75ffbzi1xhnx3nsc9jqlk9";
				};
			};
			Arjun.swagger-viewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Arjun";
					name = "swagger-viewer";
					version = "3.1.2";
					sha256 = "1cjvc99x1q5w3i2vnbxrsl5a1dr9gb3s6s9lnwn6mq5db6iz1nlm";
				};
			};
			vscoss.vscode-ansible = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscoss";
					name = "vscode-ansible";
					version = "0.6.0";
					sha256 = "0iqy8k16k4f3gdchmhcviklhwcbzx308295qzhrsi59jlm58c0x2";
				};
			};
			wmaurer.vscode-jumpy = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wmaurer";
					name = "vscode-jumpy";
					version = "0.3.1";
					sha256 = "1mrjg1swlpscfxdfqpv4vpyhamr1h4rd39pz06dgqrjqmggz52fy";
				};
			};
			ckolkman.vscode-postgres = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ckolkman";
					name = "vscode-postgres";
					version = "1.4.0";
					sha256 = "1qx7p711ag88qwpr2n9i8ak7m8isbq3kwiwn5kil00lrllh6sfh4";
				};
			};
			UVBrain.Angular2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "UVBrain";
					name = "Angular2";
					version = "0.4.1";
					sha256 = "0q7cwzr6wbbj9qk12kijm9p2casnga4cn4z31s7kl053hd77917p";
				};
			};
			jakebathman.mysql-syntax = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jakebathman";
					name = "mysql-syntax";
					version = "1.3.1";
					sha256 = "0p83jlly42i5435mwzgid9g3sjq85di3d00f6x9zm9yfpa5h0dps";
				};
			};
			small.php-ci = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "small";
					name = "php-ci";
					version = "0.4.2";
					sha256 = "1cddf8ydsrsn8xrvcm5hbcrnjwqm0jn72hg9h58avr9wrq0z63g2";
				};
			};
			vangware.dark-plus-material = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vangware";
					name = "dark-plus-material";
					version = "3.0.4";
					sha256 = "1y0irqr3lnyr69i4kcagl0wqznfjd3shxv93asbk7ajlii7ng44j";
				};
			};
			etmoffat.pip-packages = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "etmoffat";
					name = "pip-packages";
					version = "0.4.3";
					sha256 = "11wwgp5pv1wbwsfckgcw1q34mgc2pqzf843i0xldbk311jvmjwcn";
				};
			};
			serayuzgur.crates = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "serayuzgur";
					name = "crates";
					version = "0.5.10";
					sha256 = "1dbhd6xbawbnf9p090lpmn8i5gg1f7y8xk2whc9zhg4432kdv3vd";
				};
			};
			ms-vscode.Theme-MarkdownKit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "Theme-MarkdownKit";
					version = "0.1.4";
					sha256 = "1im78k2gaj6cri2jcvy727qdy25667v0f7vv3p3hv13apzxgzl0l";
				};
			};
			mtxr.sqltools-driver-mysql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mtxr";
					name = "sqltools-driver-mysql";
					version = "0.2.0";
					sha256 = "0l3apg0ickfj9j3qgr4fgvki1p0x4jrwvalp1id8fyzyskv5qlxw";
				};
			};
			be5invis.vscode-icontheme-nomo-dark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "be5invis";
					name = "vscode-icontheme-nomo-dark";
					version = "1.3.6";
					sha256 = "1l4s07z546z2bknq7dd77yc2jg701wa5i1d2rhzgbs1frgcsck0w";
				};
			};
			julialang.language-julia = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "julialang";
					name = "language-julia";
					version = "1.6.24";
					sha256 = "094hb1yvv54ixlpcsyj26s398wa19wsvwbf849g5x5c8w0s8sj5b";
				};
			};
			idleberg.icon-fonts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "idleberg";
					name = "icon-fonts";
					version = "2.5.4";
					sha256 = "0yb9mlkjgjy8a6qx0ffkwxwpl88nvdvhqizq0f1npjrywhs3ka14";
				};
			};
			AndersEAndersen.html-class-suggestions = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AndersEAndersen";
					name = "html-class-suggestions";
					version = "1.1.1";
					sha256 = "0c0qiamf1ikvjjmznxs1j43g88cnxfdpl52dvv6sbjpxsbbqq0qq";
				};
			};
			vsls-contrib.gitdoc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsls-contrib";
					name = "gitdoc";
					version = "0.0.8";
					sha256 = "018317zbxrdjs89bmrb8rq32vjw4mrb9bhhk8rhd72xy8qhan7lx";
				};
			};
			MariusAlchimavicius.json-to-ts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MariusAlchimavicius";
					name = "json-to-ts";
					version = "1.7.5";
					sha256 = "06yph6ingqnydlxr1rgvaacwcip9y4py504cqqgw5vmca78pai4r";
				};
			};
			llvm-vs-code-extensions.vscode-clangd = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "llvm-vs-code-extensions";
					name = "vscode-clangd";
					version = "0.1.17";
					sha256 = "1vgk4xsdbx0v6sy09wkb63qz6i64n6qcmpiy49qgh2xybskrrzvf";
				};
			};
			Kelvin.vscode-sshfs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Kelvin";
					name = "vscode-sshfs";
					version = "1.25.0";
					sha256 = "0v52xrm2p7b4382r7w5cy2r4m8bp2zbz8hz3sy3kgcjlkrjfjn3k";
				};
			};
			_42Crunch.vscode-openapi = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "42Crunch";
					name = "vscode-openapi";
					version = "4.9.5";
					sha256 = "125ajcb7vig6a1gnplblqgygw1plg4h3wwfdpzcadzb3lh2g5029";
				};
			};
			frhtylcn.pythonsnippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "frhtylcn";
					name = "pythonsnippets";
					version = "1.0.2";
					sha256 = "0p6jvy9b0fwgainqi86cjkvzb95avyhz13rv1vq01631358i16kg";
				};
			};
			Prisma.prisma = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Prisma";
					name = "prisma";
					version = "4.0.0";
					sha256 = "14w7ikqannkxg3ck690ix8pdzrbggiq75vgy8ag97dqkvm0lvg8l";
				};
			};
			vscjava.vscode-gradle = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vscjava";
					name = "vscode-gradle";
					version = "3.12.2022070700";
					sha256 = "1ha7br6y2z81n4gpfq5ii9cgpvf38gq1b3bka1xbcgnyjm4233zb";
				};
			};
			SirTori.indenticator = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SirTori";
					name = "indenticator";
					version = "0.7.0";
					sha256 = "0dh6gqch42v786in5kg8lfjgdldv77838qr32y32ylbrllxqv617";
				};
			};
			tintoy.msbuild-project-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tintoy";
					name = "msbuild-project-tools";
					version = "0.4.4";
					sha256 = "1zhfcnr138ag03wj6sfcg8zqzcp6s6xr49bkfp4gxcm806fmdnkj";
				};
			};
			JannisX11.batch-rename-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JannisX11";
					name = "batch-rename-extension";
					version = "0.0.5";
					sha256 = "0dwlzjm0k8xvmwppxvwblizs1nldbnz30mw0fck0l9bpyc7z1q39";
				};
			};
			DEVSENSE.phptools-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DEVSENSE";
					name = "phptools-vscode";
					version = "1.11.9824";
					sha256 = "020y706ynbm8gxqi6l0l4d8gsvv4wwa3jdxz0f0611z1hak3izkv";
				};
			};
			NuclleaR.vscode-extension-auto-import = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "NuclleaR";
					name = "vscode-extension-auto-import";
					version = "1.4.3";
					sha256 = "09z2qi1c8b14g5irp888fjr9bk5fc6vxh80r21gkydbl4vwzgavv";
				};
			};
			caolin.java-run = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "caolin";
					name = "java-run";
					version = "1.1.4";
					sha256 = "0zcmd4g5fwb625k4mkvd5kvdyka3d07vq79acq199fqhyylwdvg0";
				};
			};
			formulahendry.dotnet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "formulahendry";
					name = "dotnet";
					version = "0.0.4";
					sha256 = "1c2wxjfm6cfyllxnia7qs6h2ymhwdr4nglks39nm1wv5z84j2aa5";
				};
			};
			mindaro-dev.file-downloader = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mindaro-dev";
					name = "file-downloader";
					version = "1.0.12";
					sha256 = "1zv488sfy529vym28mkmyl2vkpfhyl9zcwyfk2k7ipq7argjmr60";
				};
			};
			nhoizey.gremlins = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nhoizey";
					name = "gremlins";
					version = "0.26.0";
					sha256 = "1sfs98nxm5ylcjrmylr5y68ddml8cfg1q1wdm7wvhfhjqx4kig9h";
				};
			};
			Atishay-Jain.All-Autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Atishay-Jain";
					name = "All-Autocomplete";
					version = "0.0.23";
					sha256 = "1ixvh3rrkfr6kvrnj7wvq0skwfjsh9whf4k1rm20wgcibfg1dpj6";
				};
			};
			mrmlnc.vscode-autoprefixer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-autoprefixer";
					version = "3.0.1";
					sha256 = "0wzgbai4ch04arg027qwljxyvc8q0m0v1jn5ak842klp18spjfl5";
				};
			};
			jithurjacob.nbpreviewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jithurjacob";
					name = "nbpreviewer";
					version = "1.2.2";
					sha256 = "1h8xv3xnmj56f5hk43jl0i9950hk0gqx6759nbimv3ddklzcxghc";
				};
			};
			YclepticStudios.unity-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "YclepticStudios";
					name = "unity-snippets";
					version = "0.1.2";
					sha256 = "0spfr1nkw9ghhi2kgpr9cfhalnbq6h8v4syh1197cbzxbr5dl2fh";
				};
			};
			ms-azuretools.vscode-azureterraform = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azureterraform";
					version = "0.3.2";
					sha256 = "15jacl5wzby56yk3k2xkhaamyfnpmsaf53sk8kj0w2vxkmwnazfk";
				};
			};
			fernandoescolar.vscode-solution-explorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fernandoescolar";
					name = "vscode-solution-explorer";
					version = "0.4.7";
					sha256 = "0d3pcbksakqggs41vcya4hykz1lxj64x43z2a77h0fv7k1ppwqwb";
				};
			};
			MS-CEINTL.vscode-language-pack-tr = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-tr";
					version = "1.69.7060939";
					sha256 = "0a4ljzndb339d2fi1dgjzckg9z2jpchjf5rmn3dmgnidwy217ql1";
				};
			};
			mariorodeghiero.vue-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mariorodeghiero";
					name = "vue-theme";
					version = "1.1.5";
					sha256 = "0jm0a3xlvqqyl64r2lsi4qsmpgaxj3l3dcbg76r67jky6mb0w85c";
				};
			};
			ms-iot.vscode-ros = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-iot";
					name = "vscode-ros";
					version = "0.8.3";
					sha256 = "1kqmc41svlkf8v1qn4cpsh5hchq8by8ym2xwsv79mnxj0cgpyb4w";
				};
			};
			silvenon.mdx = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "silvenon";
					name = "mdx";
					version = "0.1.0";
					sha256 = "1mzsqgv0zdlj886kh1yx1zr966yc8hqwmiqrb1532xbmgyy6adz3";
				};
			};
			OBKoro1.korofileheader = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "OBKoro1";
					name = "korofileheader";
					version = "4.9.1";
					sha256 = "09dmz0lxd84h8cs5jpdrmqf69763c782qw1dhp98llmagjfga8w8";
				};
			};
			jakethashi.vscode-angular2-emmet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jakethashi";
					name = "vscode-angular2-emmet";
					version = "2.0.3";
					sha256 = "0c4m1yk3x0nwnzmyh9f9b199hqmm3qiii8i8ddjc14rwnpjmls0k";
				};
			};
			thenikso.github-plus-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "thenikso";
					name = "github-plus-theme";
					version = "1.4.3";
					sha256 = "0qxv007pr28ghgjb0dal9x5nqi8l507nz96c4hm6f4jnyljdyada";
				};
			};
			Fudge.auto-using = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Fudge";
					name = "auto-using";
					version = "0.7.15";
					sha256 = "1vjf55vk2bc921hvpifd4c2aplp7wmqsp5aiq00q3jxpxqwsarim";
				};
			};
			davidbabel.vscode-simpler-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "davidbabel";
					name = "vscode-simpler-icons";
					version = "1.6.5";
					sha256 = "0cay9x6csi210j9c1lrh70j333jpip367iycknna5bn5ckg7mgib";
				};
			};
			MarlinFirmware.auto-build = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MarlinFirmware";
					name = "auto-build";
					version = "2.1.41";
					sha256 = "1rvjsq8nmiwbdhk3bpnc21myy17yzi2qz0zr566ckgmv18dx4z4d";
				};
			};
			HookyQR.minify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HookyQR";
					name = "minify";
					version = "0.4.3";
					sha256 = "0pc8xzv9hx2xyjqs5ffg42858lga901i8qldlz95c0avsy5wyj4a";
				};
			};
			phproberto.vscode-php-getters-setters = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "phproberto";
					name = "vscode-php-getters-setters";
					version = "1.2.3";
					sha256 = "1zba74azr7adl8874b8r0aixdhf026s2w1i1caz0nd62772qp2sy";
				};
			};
			austenc.laravel-blade-spacer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "austenc";
					name = "laravel-blade-spacer";
					version = "2.1.3";
					sha256 = "0ypv84h4mh02nfh5saqlvd14ayx6xv2mk3la7d7w7gbjcfcpgkhj";
				};
			};
			cipchk.cssrem = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cipchk";
					name = "cssrem";
					version = "3.0.0";
					sha256 = "1r9wppn0aanmdfqkf9m4p0kz0zx1h5rdr0kmjkz1jqavxjckh078";
				};
			};
			yuichinukiyama.vscode-preview-server = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yuichinukiyama";
					name = "vscode-preview-server";
					version = "1.3.0";
					sha256 = "1vaskz4rn6s2v981zdsfbi5pp5g2i41br5p2jrrlkchq2m9zi4dh";
				};
			};
			chris-noring.node-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "chris-noring";
					name = "node-snippets";
					version = "1.3.3";
					sha256 = "15ybv6xxbkl3sfyw49wf29vf98yylavkqbr57cp4d112x2nky033";
				};
			};
			hnw.vscode-auto-open-markdown-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hnw";
					name = "vscode-auto-open-markdown-preview";
					version = "0.0.4";
					sha256 = "0jp1pmz1f8ng4xjrp5vkks5d9ig715c4l4ca2ilsvq84h5r7jli8";
				};
			};
			dan-c-underwood.arm = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dan-c-underwood";
					name = "arm";
					version = "1.7.4";
					sha256 = "1xs5sfppdl7dkh4lyqsipfwax85jpn95rivpqas3z800rpvlr441";
				};
			};
			mads-hartmann.bash-ide-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mads-hartmann";
					name = "bash-ide-vscode";
					version = "1.14.0";
					sha256 = "058z0fil0xpbnay6b5hgd31bgd3k4x3rnfyb8n0a0m198sxrpd5z";
				};
			};
			sianglim.slim = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sianglim";
					name = "slim";
					version = "0.1.2";
					sha256 = "0k63dh7j6k5ci9y3wy4nyawr2l5rszw7lwqngayn0nkwxpdjd23x";
				};
			};
			marus25.cortex-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marus25";
					name = "cortex-debug";
					version = "1.5.1";
					sha256 = "1bh2xyal6wvn6dbklly3fnhh8rrnbi980lgxpzvxskp63zxbk2lz";
				};
			};
			seanwu.vscode-qt-for-python = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "seanwu";
					name = "vscode-qt-for-python";
					version = "1.1.7";
					sha256 = "1lh59p4m7sfi7n09wns0b4m4zy0znjyw0p031virk5bgymiw2w5q";
				};
			};
			searKing.preview-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "searKing";
					name = "preview-vscode";
					version = "2.2.5";
					sha256 = "137ij947bjg3qna093jngvrfz30053ja5kjs14ai0gd4hm90dg3z";
				};
			};
			cjhowe7.laravel-blade = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cjhowe7";
					name = "laravel-blade";
					version = "1.1.2";
					sha256 = "1v9hxjw1l20wxv5zp9d9314zwf1y15npgjd4cr46wb0cmh4789pk";
				};
			};
			vsciot-vscode.azure-iot-toolkit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsciot-vscode";
					name = "azure-iot-toolkit";
					version = "2.17.0";
					sha256 = "0ipd9jwj4hky1cq0g5d8cd74i3jhdw3jrpxfb1rdxpg2vamn8rg6";
				};
			};
			ban.spellright = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ban";
					name = "spellright";
					version = "3.0.64";
					sha256 = "1v8axhhz04js7a2khc8ydg22kk7wydcnzz9hjg4my26p796wq9iq";
				};
			};
			shakram02.bash-beautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shakram02";
					name = "bash-beautify";
					version = "0.1.1";
					sha256 = "1xqrjmpgbjj6bfr5643bnhj9jxwiswkhwpk2jvapwwiy94c6f3d6";
				};
			};
			jbenden.c-cpp-flylint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jbenden";
					name = "c-cpp-flylint";
					version = "1.11.0";
					sha256 = "0jyksvqz0c9819a8s2nnam0s59jd6dyb4y399d8ran5mdfy5hh56";
				};
			};
			naumovs.theme-oceanicnext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "naumovs";
					name = "theme-oceanicnext";
					version = "0.0.4";
					sha256 = "0glf78m08nj92igx70540s95czzxz3a4hvaavrcxbl7cpmca32df";
				};
			};
			AESSoft.aessoft-class-autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AESSoft";
					name = "aessoft-class-autocomplete";
					version = "0.1.0";
					sha256 = "0cf0z16n7dhc5m9gzg4kl3hlxyw0sqjmpm7hs3cxcx42jglnvimw";
				};
			};
			kreativ-software.csharpextensions = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kreativ-software";
					name = "csharpextensions";
					version = "1.7.0";
					sha256 = "1c7967viclrhgdzxx8b8fpv633q9szzaxmbhapiha45bnc261z4l";
				};
			};
			DiemasMichiels.emulate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DiemasMichiels";
					name = "emulate";
					version = "1.6.0";
					sha256 = "1k9f0vwlpc0dw1mphvayfnnf31hlw8pcy73lqi9dnp2gmxv26sjy";
				};
			};
			cmstead.jsrefactor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cmstead";
					name = "jsrefactor";
					version = "3.0.1";
					sha256 = "0j5g0667pk3hkbqr0dmfdl5f7s0h86wjfkhcdb2iqbq44mddi6yi";
				};
			};
			JakeBecker.elixir-ls = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JakeBecker";
					name = "elixir-ls";
					version = "0.10.0";
					sha256 = "0klvw14jg3hrb4xcdsp0zrjbqrygrbhphqzb9hx1qa7anp2d8wwb";
				};
			};
			bibhasdn.django-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bibhasdn";
					name = "django-snippets";
					version = "1.1.1";
					sha256 = "00f5h7rhk7133jvh6mnql66szxz4vxrypql66r6n6qz9dfvg2m6c";
				};
			};
			mblode.twig-language-2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mblode";
					name = "twig-language-2";
					version = "0.9.2";
					sha256 = "1y8ha04wlfpky2d0y94x878miaka978px6s5cqrdwqlgsg3kwifl";
				};
			};
			softwaredotcom.swdc-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "softwaredotcom";
					name = "swdc-vscode";
					version = "2.6.32";
					sha256 = "16xqwlsqrcxw8sw10g9iddpm3jz4ahk69i56xd5q80fbgkx6r8xm";
				};
			};
			apollographql.vscode-apollo = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "apollographql";
					name = "vscode-apollo";
					version = "1.19.11";
					sha256 = "1r9p82mf5xsh7bk58pjbf92vamib1d2gs490wzlhz2w97dy5wb0j";
				};
			};
			shenjiaolong.vue-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shenjiaolong";
					name = "vue-helper";
					version = "2.4.7";
					sha256 = "0r67g9svm3c1max708jddgih41s15h76zgjj1w2hbflkgxvwa91s";
				};
			};
			mindaro.mindaro = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mindaro";
					name = "mindaro";
					version = "1.0.120220125";
					sha256 = "0vlpk2b14r8gmy4z61yx5s4qcgh83j97z1g9b6r71vig9mdnm14w";
				};
			};
			jeroen-meijer.pubspec-assist = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jeroen-meijer";
					name = "pubspec-assist";
					version = "2.3.2";
					sha256 = "1zdv8i6i4hka536i52qbqpmghs6jyn22vgzxp7jfnvxvx9nirjgq";
				};
			};
			RandomFractalsInc.vscode-data-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "RandomFractalsInc";
					name = "vscode-data-preview";
					version = "2.3.0";
					sha256 = "1zasffg86c295qmw68516qm0sgsc3p99yz132xa9kcklvclw1ac4";
				};
			};
			bierner.markdown-emoji = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "markdown-emoji";
					version = "0.2.1";
					sha256 = "1lcg2b39jydl40wcfrbgshl2i1r58k92c7dipz0hl1fa1v23vj4v";
				};
			};
			LaurentTreguier.vscode-simple-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "LaurentTreguier";
					name = "vscode-simple-icons";
					version = "1.16.0";
					sha256 = "1fqj8f9q1msqm2j0jqbxnnx330rg5y5d260hzs94qj87adx7flkl";
				};
			};
			xyz.plsql-language = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xyz";
					name = "plsql-language";
					version = "1.8.2";
					sha256 = "16xxa6w03wzd95v1cycmjvw9hfg3chvpclrn28v0qsa3lir1mxrr";
				};
			};
			GregorBiswanger.json2ts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GregorBiswanger";
					name = "json2ts";
					version = "0.0.6";
					sha256 = "1rpiy7f9hcx8c87fv3jj0hvp6s6xsvl1w7mw02fgxrdzqi62aafg";
				};
			};
			ms-dotnettools.dotnet-interactive-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-dotnettools";
					name = "dotnet-interactive-vscode";
					version = "1.0.3314011";
					sha256 = "01vx9552xib0z6r1w6p1nizk2pg7wcvbawjrkglkf4rjph0m66vr";
				};
			};
			sburg.vscode-javascript-booster = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sburg";
					name = "vscode-javascript-booster";
					version = "14.0.1";
					sha256 = "0189jyyxa3spv7cikqb077ms7gpi9r2wp1ymx28ad636srnq1ml8";
				};
			};
			keyring.Lua = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "keyring";
					name = "Lua";
					version = "0.0.9";
					sha256 = "1vgv37qqgdz5dy49ixq4yxr5p9qij2z3x80dk5bbl4ny0nkbs090";
				};
			};
			ms-ossdata.vscode-postgresql = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-ossdata";
					name = "vscode-postgresql";
					version = "0.3.0";
					sha256 = "02sp5sv1sapynq4xx04b9z86jz2vmcsma1cpkbd05k2cw5g999lk";
				};
			};
			MS-CEINTL.vscode-language-pack-pl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MS-CEINTL";
					name = "vscode-language-pack-pl";
					version = "1.69.7060956";
					sha256 = "0pmq3gg44brz605h0pbh7xmczgfri4l1p8h28m4hc5za5iyafhir";
				};
			};
			SimonSiefke.prettier-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SimonSiefke";
					name = "prettier-vscode";
					version = "2.0.7";
					sha256 = "0fy1gcwq3xc1aw2izgbgb982mwxydh9vcjq1f8bvmjf3sylvk3mj";
				};
			};
			wordpresstoolbox.wordpress-toolbox = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wordpresstoolbox";
					name = "wordpress-toolbox";
					version = "1.3.12";
					sha256 = "0j0xa3qy3n0j7kf8gdw7vvl7ad4s3vzpmj60vy0l7zi12gs4mm1d";
				};
			};
			Askia.askia-qexml-generator-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Askia";
					name = "askia-qexml-generator-extension";
					version = "1.0.1";
					sha256 = "1jphfbs9840k8ng9hr63rprnk1ah3hk17zbw455as7q3ya323687";
				};
			};
			glen-84.sass-lint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "glen-84";
					name = "sass-lint";
					version = "1.0.7";
					sha256 = "0k67llyv24igjv0v66hp5arn2z7klrssjld2hz92mq640j8kafg9";
				};
			};
			actboy168.lua-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "actboy168";
					name = "lua-debug";
					version = "1.58.2";
					sha256 = "1j8snq74knad0mkarrvsiml1nf3mbfjxz6rb1h0byrjbyxbg65w1";
				};
			};
			shengchen.vscode-checkstyle = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shengchen";
					name = "vscode-checkstyle";
					version = "1.4.1";
					sha256 = "1rja5ysnyxsz9k08nx4vdz9f8a57wgq5j2677i2ylr3k4zclal73";
				};
			};
			ms-vscode.anycode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "anycode";
					version = "0.0.68";
					sha256 = "13qhp7s5p8lb14kb5q3nrirxh7cz2bhak5nzf7bmh4har9kdjcgf";
				};
			};
			BeardedBear.beardedtheme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "BeardedBear";
					name = "beardedtheme";
					version = "6.6.0";
					sha256 = "18wxj8byqir63w005x6i4h7kyii2qfq2wibbkrkywyk5xpcx9mnj";
				};
			};
			rocketseat.theme-omni = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rocketseat";
					name = "theme-omni";
					version = "1.0.12";
					sha256 = "1dbmzabrz08x8lca387a4v0l325aiaxqi0k52v25h2b2rwqz575d";
				};
			};
			lukasz-wronski.ftp-sync = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lukasz-wronski";
					name = "ftp-sync";
					version = "0.3.9";
					sha256 = "1r9hnpqnrcagk88n78zvhbqsi9zywds1kql0w3j7qz76fzm86xa7";
				};
			};
			deerawan.vscode-faker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "deerawan";
					name = "vscode-faker";
					version = "2.0.0";
					sha256 = "00naicby80fr556apf9q8q3nyjvfibimb8k2l0lnd3c8zzqsp2bl";
				};
			};
			_1tontech.angular-material = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "1tontech";
					name = "angular-material";
					version = "0.13.0";
					sha256 = "199pp9s2zwq6sm49zf8n93hm1k4nwvgraxik4gy0812nlaw94h3b";
				};
			};
			torn4dom4n.latex-support = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "torn4dom4n";
					name = "latex-support";
					version = "4.0.0";
					sha256 = "1v1n8x8a13j8w1smmcr8vrblyxsr795zjb90cqs7shjl5q3l8ja7";
				};
			};
			infeng.vscode-react-typescript = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "infeng";
					name = "vscode-react-typescript";
					version = "1.3.1";
					sha256 = "1fmnpxmkpj7aanmrac9xfsgzm7bp8zl51cqhqyzjk44gmafav8kr";
				};
			};
			TaodongWu.ejs-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "TaodongWu";
					name = "ejs-snippets";
					version = "0.1.0";
					sha256 = "0qwzn2fhjmmjnyz6ifchz59dn1sgrwjwqxcv950fgpy5fxjcbgiq";
				};
			};
			oouo-diogo-perdigao.docthis = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oouo-diogo-perdigao";
					name = "docthis";
					version = "0.8.2";
					sha256 = "1v7njs8l283k0l05rn6zbm76hmk6dg2hgbkm36bdka27kxqnxacd";
				};
			};
			SimonTest.simontest = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SimonTest";
					name = "simontest";
					version = "1.9.10";
					sha256 = "04fnr0npmwh1qwpriyrqxhfbay9a6zb1m96yqrka0kwv4nmqm108";
				};
			};
			mcright.auto-save = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mcright";
					name = "auto-save";
					version = "1.0.3";
					sha256 = "0xmli47k7zviljnnaabh44z1sl82dcc3pssqgp716amzy83dl5a9";
				};
			};
			ms-vscode.node-debug2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "node-debug2";
					version = "1.43.0";
					sha256 = "1nrx2qbhcsxafqw0rj42adnm96jnc05adnj777a4b7lkv818kljs";
				};
			};
			felipe-mendes.slack-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "felipe-mendes";
					name = "slack-theme";
					version = "1.9.17";
					sha256 = "13ilhcwzimk2apia3ld0rilvrrra07cr1wkypn786qzfs6hryvx8";
				};
			};
			fabiospampinato.vscode-diff = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fabiospampinato";
					name = "vscode-diff";
					version = "1.4.2";
					sha256 = "0dq3hlpn72kck7wlcjl2blir3mvk6m356kmjbsjlr49qwsdpwlvg";
				};
			};
			Compulim.compulim-vscode-closetag = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Compulim";
					name = "compulim-vscode-closetag";
					version = "1.2.0";
					sha256 = "0aa1azl24plxdfcd4v24l8jgw2daydwz5ncldmv6y82rk9wy7izg";
				};
			};
			patbenatar.advanced-new-file = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "patbenatar";
					name = "advanced-new-file";
					version = "1.2.2";
					sha256 = "09a6yldbaz9d7gn9ywkqd96l3pkc0y30b6b02nv2qigli6aihm6g";
				};
			};
			financialforce.lana = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "financialforce";
					name = "lana";
					version = "1.4.2";
					sha256 = "0ydf4zz335hmmc658k5ia36cszvr84l6xazm2qb7816gg85v6bza";
				};
			};
			daylerees.rainglow = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "daylerees";
					name = "rainglow";
					version = "1.5.2";
					sha256 = "1i345sx2aafd4slyq453gjqmjvchyvj338zsq5j709zfi50z3kym";
				};
			};
			mosapride.zenkaku = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mosapride";
					name = "zenkaku";
					version = "0.0.3";
					sha256 = "0abbgg0mjgfy5495ah4iiqf2jck9wjbflvbfwhwll23g0wdazlr5";
				};
			};
			imperez.smarty = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "imperez";
					name = "smarty";
					version = "0.3.0";
					sha256 = "1vphwasgcnck1xwasg582gxqfj509vmxx5ix8nx9m8f90pfwmxh6";
				};
			};
			jdinhlife.gruvbox = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jdinhlife";
					name = "gruvbox";
					version = "1.7.0";
					sha256 = "176q9zbsxhvk5bxwd7pza1xv6vcrdksx9559mxp22ik2sdxp460v";
				};
			};
			mubaidr.vuejs-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mubaidr";
					name = "vuejs-extension-pack";
					version = "1.9.0";
					sha256 = "0aijwa3hqkx51ng4mq0kf0pg5jcd7qi7lbblkm98qpfyx5xpi73g";
				};
			};
			bierner.markdown-checkbox = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "markdown-checkbox";
					version = "0.3.2";
					sha256 = "12mjacyy3ipinhmaz35972vn1dahrzwlbx16n1wjyvxsl8l4id0y";
				};
			};
			bierner.emojisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "emojisense";
					version = "0.9.1";
					sha256 = "1y5s4ciksd225rf6ms736xfmpnyha8ms395ah2j7ac5a5nd4iy3d";
				};
			};
			tobiasalthoff.atom-material-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tobiasalthoff";
					name = "atom-material-theme";
					version = "1.10.8";
					sha256 = "0i31a0id7f48qm7gypspcrasm6d4rfy7r2yl04qvg2kpwp858fs4";
				};
			};
			clinyong.vscode-css-modules = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "clinyong";
					name = "vscode-css-modules";
					version = "0.4.2";
					sha256 = "0aiw8haf3q44hp33ngmxih5w96varrzjfmmzrpnxagx01hygygsf";
				};
			};
			sporiley.css-auto-prefix = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sporiley";
					name = "css-auto-prefix";
					version = "0.1.7";
					sha256 = "1459lq77fipz4ln8f5x9h2rg90kkl15197y4vlr1k1nlmla9aqy6";
				};
			};
			sdras.vue-vscode-extensionpack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sdras";
					name = "vue-vscode-extensionpack";
					version = "0.2.0";
					sha256 = "0xf6bxv922h3y1ckrn25mk6hmavr8c5xc59dprcj7q66z2j87g0s";
				};
			};
			necinc.elmmet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "necinc";
					name = "elmmet";
					version = "1.0.1";
					sha256 = "1sl9fd26ki1yxqcfdfxnwr1z5gmlwwcshrrb2csj4f18zlm3bqa4";
				};
			};
			eppz.eppz-code = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eppz";
					name = "eppz-code";
					version = "1.2.52";
					sha256 = "0qfpbm000yq2gg3q12a6j97jf7qdvdndvgbasc0qhwlnl4gq92an";
				};
			};
			bigonesystems.django = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bigonesystems";
					name = "django";
					version = "1.0.2";
					sha256 = "0dyd13h5kjhh93x3zlv7a1a16prghmn0v6q3lhmcwhwd51lay6ah";
				};
			};
			DSnake.java-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DSnake";
					name = "java-debug";
					version = "0.0.2";
					sha256 = "1005rj80bkib2v0149bi5pwxyzg835d7nblvswn71hgbgx5g1h0q";
				};
			};
			schneiderpat.aspnet-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "schneiderpat";
					name = "aspnet-helper";
					version = "0.6.4";
					sha256 = "1fi1pfy8k5y1lndpjgfvycv8r4iqai1pgnq68q8f678hx05x88a6";
				};
			};
			stkb.rewrap = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "stkb";
					name = "rewrap";
					version = "17.8.0";
					sha256 = "1y168ar01zxdd2x73ddsckbzqq0iinax2zv3d95nhwp9asjnbpgn";
				};
			};
			bung87.rails = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bung87";
					name = "rails";
					version = "0.17.8";
					sha256 = "1p6s0svhw677qr3hxpr64ym1pph5bvbnwdn5hs64zi0hmibzyz2j";
				};
			};
			nobuhito.printcode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nobuhito";
					name = "printcode";
					version = "3.0.0";
					sha256 = "0nms3fd401mimg9ansnqadnmg77f3n3xh98bpcqxhln4562rmv9b";
				};
			};
			styled-components.vscode-styled-components = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "styled-components";
					name = "vscode-styled-components";
					version = "1.7.4";
					sha256 = "0qx1mvvw0bqa0psm35yxv9lvzw40bp8syjx4sp13502hg63r4h7n";
				};
			};
			McCarter.start-git-bash = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "McCarter";
					name = "start-git-bash";
					version = "1.2.1";
					sha256 = "1rmr82adg2bqnyw2grvdidy124ixz6lmmcki2k8jqyp2h58hiiys";
				};
			};
			adelphes.android-dev-ext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adelphes";
					name = "android-dev-ext";
					version = "1.3.2";
					sha256 = "014q47pci0mcsk1ihgc3z1bi118jalr8wpn5xxwwdhrnmmf34gi6";
				};
			};
			mikey.vscode-fileheader = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mikey";
					name = "vscode-fileheader";
					version = "0.0.2";
					sha256 = "1nsz2g7rrn6mlkxrks2808xp8wm8lcwsk7al7c5hi0yin54nc43p";
				};
			};
			idleberg.hopscotch = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "idleberg";
					name = "hopscotch";
					version = "0.8.2";
					sha256 = "0dwdfi7smh2l9j5pj9s8a8mx82z8avg6p3w1qd721d3dcgblf273";
				};
			};
			YouMayCallMeV.vscode-java-saber = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "YouMayCallMeV";
					name = "vscode-java-saber";
					version = "0.1.2";
					sha256 = "1as5h6cr5b9wiklc5qavwlr7mp2aj01xzqwsjgfrhn778zhb7za4";
				};
			};
			albert.TabOut = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "albert";
					name = "TabOut";
					version = "0.2.1";
					sha256 = "14dw7k80g6yf94s8446vz70zg5khsbhisz89633k7ymmajx4hq6n";
				};
			};
			HvyIndustries.crane = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HvyIndustries";
					name = "crane";
					version = "0.3.8";
					sha256 = "1pcz4sa57vd23q3vwmgjg1n1br72val793bi1agfhd6h2kf7ik25";
				};
			};
			fivethree.vscode-ionic-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fivethree";
					name = "vscode-ionic-snippets";
					version = "2.2.2";
					sha256 = "1d9356m0iivdinqdgfnhp3c5qymap19viv172g815dp8jmqb7llh";
				};
			};
			luanpotter.dart-import = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "luanpotter";
					name = "dart-import";
					version = "0.3.1";
					sha256 = "10rvcgi5m6c76fk51nrbs8fy5pz2wq8s21w0mv2jm0qp8zq10yr0";
				};
			};
			IronGeek.vscode-env = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "IronGeek";
					name = "vscode-env";
					version = "0.1.0";
					sha256 = "1ygfx1p38dqpk032n3x0591i274a63axh992gn6z1d45ag9bs6ji";
				};
			};
			haskell.haskell = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "haskell";
					name = "haskell";
					version = "2.2.0";
					sha256 = "0qgp93m5d5kz7bxlnvlshcd8ms5ag48nk5hb37x02giqcavg4qv0";
				};
			};
			richie5um2.vscode-sort-json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "richie5um2";
					name = "vscode-sort-json";
					version = "1.20.0";
					sha256 = "1zcbdzsv6vv3zwx5ddbarqizs8s9s57dnf328waq8jgqyzjg31i6";
				};
			};
			mjmcloug.vscode-elixir = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mjmcloug";
					name = "vscode-elixir";
					version = "1.1.0";
					sha256 = "0kj7wlhapkkikn1md8cknrffrimk0g0dbbhavasys6k3k7pk2khh";
				};
			};
			fabiospampinato.vscode-todo-plus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fabiospampinato";
					name = "vscode-todo-plus";
					version = "4.18.4";
					sha256 = "0fsavcj5k6ksdfcsnrhr7ybnd5fxljljggavmjkjcr8gamw8r8km";
				};
			};
			stevencl.addDocComments = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "stevencl";
					name = "addDocComments";
					version = "0.0.8";
					sha256 = "08572fhn6ilfbx8zwn849ab3npyfkh9m5mk2br6sii601s9k5vrk";
				};
			};
			bung87.vscode-gemfile = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bung87";
					name = "vscode-gemfile";
					version = "0.4.2";
					sha256 = "1kh4wz7fiafm95wln9npabplnsldbxv2n3h5wjp34w91vl4x0q19";
				};
			};
			funkyremi.vscode-google-translate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "funkyremi";
					name = "vscode-google-translate";
					version = "1.4.13";
					sha256 = "1klwvkwkwirbylm749rfdk14zagz0k9qn1ldrlvy3mc31abklnpm";
				};
			};
			uloco.theme-bluloco-light = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "uloco";
					name = "theme-bluloco-light";
					version = "3.6.1";
					sha256 = "051nrqil44d0g8lx72vk858cgv2i1q6369fm48qfdswix6vjk4iq";
				};
			};
			hwencc.html-tag-wrapper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hwencc";
					name = "html-tag-wrapper";
					version = "0.2.3";
					sha256 = "1d60sv56q4xgpka2hp80jzivly36qnm414y71sapyghxkrcbzrqi";
				};
			};
			bceskavich.theme-dracula-at-night = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bceskavich";
					name = "theme-dracula-at-night";
					version = "2.7.1";
					sha256 = "1ipsmdswvk9izph2hvvyxqwjmpzqygjba4dv88siqlw07sc16rvp";
				};
			};
			in4margaret.compareit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "in4margaret";
					name = "compareit";
					version = "0.0.2";
					sha256 = "1zqff3wxwd1jcrw0r2hjpba7ndi9rjl5skzwr4x9z6rp9vihx6f2";
				};
			};
			slevesque.vscode-multiclip = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "slevesque";
					name = "vscode-multiclip";
					version = "0.1.5";
					sha256 = "1cg8dqj7f10fj9i0g6mi3jbyk61rs6rvg9aq28575rr52yfjc9f9";
				};
			};
			cstrap.flask-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cstrap";
					name = "flask-snippets";
					version = "0.1.3";
					sha256 = "1vfyby0kpcrachc3jy2wccbi1gwdykx307ym8zfsln5gvsagljp2";
				};
			};
			slevesque.vscode-autohotkey = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "slevesque";
					name = "vscode-autohotkey";
					version = "0.2.2";
					sha256 = "11h4nzpxa6npdfjvairgdwr626csqpj3wy3kxryzxzznbyj6a4z2";
				};
			};
			ysemeniuk.emmet-live = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ysemeniuk";
					name = "emmet-live";
					version = "1.0.0";
					sha256 = "1k2x2pj06vymxlkxmrn0wdp48y3ll5zi671yqr1c4n2gsm6l4ihh";
				};
			};
			brapifra.c-compiler = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "brapifra";
					name = "c-compiler";
					version = "0.0.4";
					sha256 = "1b7h1hc22zcx9p7c1rvibrybphplkgq8j25w3zcxjw9qkfjilq1s";
				};
			};
			scalameta.metals = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "scalameta";
					name = "metals";
					version = "1.18.2";
					sha256 = "1vmbiqajchmak4h50q1fqjw309zj6xh07sx21sqfkx083q6kag04";
				};
			};
			ms-vscode.remote-repositories = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "remote-repositories";
					version = "0.14.0";
					sha256 = "1ldxdq2ixq1pj4mr8cflr7vmapafyqgqxzivn7b05xyc1rwrf534";
				};
			};
			emilast.LogFileHighlighter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "emilast";
					name = "LogFileHighlighter";
					version = "2.16.0";
					sha256 = "0s8jywb8y9fva6p7j2kkw8x862k3h179q9907amznx394mjgk531";
				};
			};
			gornivv.vscode-flutter-files = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gornivv";
					name = "vscode-flutter-files";
					version = "4.3.1";
					sha256 = "1d7wcycxs56sywnnfxnbl8pyg0ibf0hbv5fh0ism5crfls379p4b";
				};
			};
			mtxr.sqltools-driver-pg = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mtxr";
					name = "sqltools-driver-pg";
					version = "0.2.0";
					sha256 = "0ws17sna87rs4ihcdj5lzxf8g2nkcgyjpqlafl5kii2c8x364y6j";
				};
			};
			savadkuhipublisher.autoreactpro = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "savadkuhipublisher";
					name = "autoreactpro";
					version = "0.3.4";
					sha256 = "1s7gifc4xirgzk1bq6sn8iqiicdllh5kkjrymkz9y9g078c7g2f2";
				};
			};
			nodesource.vscode-for-node-js-development-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nodesource";
					name = "vscode-for-node-js-development-pack";
					version = "2.0.1";
					sha256 = "0xs3fxik8va8rhzmbv3yq3jb2b49sc27y6llhs2vgy2n20q6hhlk";
				};
			};
			AngularDoc.angulardoc-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AngularDoc";
					name = "angulardoc-vscode";
					version = "6.1.3";
					sha256 = "048x53qg47j5kp2i3xga4z70nvdhq92sj8ghnwphx9nzv2j472ql";
				};
			};
			sohibe.java-generate-setters-getters = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sohibe";
					name = "java-generate-setters-getters";
					version = "7.4.0";
					sha256 = "1p9ysyrki6x6rgyid5jvyfr324cc281305q8j7kk2sqp9h5mq8vg";
				};
			};
			solnurkarim.html-to-css-autocompletion = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "solnurkarim";
					name = "html-to-css-autocompletion";
					version = "1.1.2";
					sha256 = "1y34caiswsffqxj7jd5wlxk6fxzdyfgzhljii17hwi53qr4zmkcn";
				};
			};
			gamunu.vscode-yarn = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gamunu";
					name = "vscode-yarn";
					version = "2.1.0";
					sha256 = "0kh989fm1p4j9in3ci44pjzlckj85m22zhkz4hlcsbjcqirfijqi";
				};
			};
			pthorsson.vscode-jsp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pthorsson";
					name = "vscode-jsp";
					version = "0.0.3";
					sha256 = "06dv2w39vykm0fh97ld3f9f5fp182dbfsh55hg6f6jc8plrmls69";
				};
			};
			bukas.GBKtoUTF8 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bukas";
					name = "GBKtoUTF8";
					version = "0.0.2";
					sha256 = "0fzyi29swlqydhjzz5bqaixym65hy5pcx7h06bm9nnhvrzgg5g5m";
				};
			};
			denoland.vscode-deno = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "denoland";
					name = "vscode-deno";
					version = "3.13.0";
					sha256 = "19rm6j52xwfkaxhsfplx2m7zfc9qzci72qxdpm7r855bkgab9mcs";
				};
			};
			Oracle.oracledevtools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Oracle";
					name = "oracledevtools";
					version = "21.4.0";
					sha256 = "1164mc1miwychqgpa8lmx0aqqwy7xlhh8g9ym1g711z9473vzdag";
				};
			};
			jaycetyle.vscode-gnu-global = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jaycetyle";
					name = "vscode-gnu-global";
					version = "0.3.5";
					sha256 = "15642cccq4qh64q6h1qbi2m5spxch28453wra284ih1mbn50s62c";
				};
			};
			ms-vscode.Theme-MaterialKit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "Theme-MaterialKit";
					version = "0.1.4";
					sha256 = "1lqql7lb974mix00sad01d88d5mgyzrh1ck7xpgsdl5kqqag0w3a";
				};
			};
			olback.es6-css-minify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "olback";
					name = "es6-css-minify";
					version = "3.3.3";
					sha256 = "0s2ds3rrk9ynppaaka8pq1aa0bkpp5bmm2sv9ddnvcw8yjz2scqa";
				};
			};
			csstools.postcss = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "csstools";
					name = "postcss";
					version = "1.0.9";
					sha256 = "0rbkzfa5czc7ah3ijl7hrrqiwzyyicqr2mkyzzsy9smqcwm874g6";
				};
			};
			docsmsft.docs-markdown = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "docsmsft";
					name = "docs-markdown";
					version = "0.2.113";
					sha256 = "1b17x6l8lpr37dwch5lfbhm4as9k1jrdbp7bajlnvby069h1xaik";
				};
			};
			VisualStudioExptTeam.intellicode-api-usage-examples = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "VisualStudioExptTeam";
					name = "intellicode-api-usage-examples";
					version = "0.1.2";
					sha256 = "06xw4zhivgpyf3hbkrhrg9kp3sbmanbyr8zp29hmgdmpvqzzsp1c";
				};
			};
			CodeStream.codestream = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "CodeStream";
					name = "codestream";
					version = "13.2.0";
					sha256 = "0by0smjyvz26zbw4pkid7dqy3jd355rvj84zv2j9wk8qmajrbyzx";
				};
			};
			asciidoctor.asciidoctor-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "asciidoctor";
					name = "asciidoctor-vscode";
					version = "3.0.0";
					sha256 = "0q28krz1ms0lsaqm88yvsavc880jgkqcin0j9frpb4x90vqna4wc";
				};
			};
			JerryHong.autofilename = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JerryHong";
					name = "autofilename";
					version = "0.1.3";
					sha256 = "19vnlrv1wk2bkq23acfm6j08mmgff0asyzw5pn03a74bhh08rr5s";
				};
			};
			alefragnani.pascal = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alefragnani";
					name = "pascal";
					version = "9.5.0";
					sha256 = "0vhrssccifrj82q0j8c28flka916g33nyvdm3bjz3p9w8fy8sbv1";
				};
			};
			loiane.angular-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "loiane";
					name = "angular-extension-pack";
					version = "1.0.0";
					sha256 = "1ca67sa7xv1kh8l4m8xq1h5kz1025s7xh82ncpy008j14ggrmj7g";
				};
			};
			p1c2u.docker-compose = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "p1c2u";
					name = "docker-compose";
					version = "0.3.5";
					sha256 = "0ghyy5zll82yp0ddxspwcaa47dycc2g8lgy47wj7jvgiqdh1g5aw";
				};
			};
			Wscats.cors-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Wscats";
					name = "cors-browser";
					version = "1.0.11";
					sha256 = "0grbsm2bjh9cccid0qnaxrza52ydbzhy8lm7p4pk67acrdbs7pxz";
				};
			};
			ms-vscode.PowerShell-Preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "PowerShell-Preview";
					version = "2022.6.3";
					sha256 = "092akpy7q5prxazb0pwpng3spk4dfgsjqb95nxngh27akac0lfr7";
				};
			};
			kuscamara.electron = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kuscamara";
					name = "electron";
					version = "0.2.6";
					sha256 = "1p9rq8x4pk9dbbbgz0smc6fismgs8ls5w7igdb6sd2a5jxvhkja4";
				};
			};
			william-voyek.vscode-nginx = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "william-voyek";
					name = "vscode-nginx";
					version = "0.7.2";
					sha256 = "0s4akrhdmrf8qwn6vp8kc31k5hx2k2wml5mcashfc09hxiqsf2cq";
				};
			};
			mikeburgh.xml-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mikeburgh";
					name = "xml-format";
					version = "1.1.2";
					sha256 = "0zds0d7dji7a70y8w81li347bk55k0cj05l71xzbrqswgp9nkf6i";
				};
			};
			ikappas.composer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ikappas";
					name = "composer";
					version = "0.8.0";
					sha256 = "1rrg4s41v4h2483d5zhvqwyyn93abaz1w23x1pv7d9d666hz195v";
				};
			};
			ms-vscode.node-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "node-debug";
					version = "1.45.0";
					sha256 = "1szgz1zqwdlgjdycjf7s2km8lwplljxidccdibajxxzmzgf954v7";
				};
			};
			FelixAngelov.bloc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "FelixAngelov";
					name = "bloc";
					version = "6.6.1";
					sha256 = "0xi7yzk9lbpjjqgyph1zas2dr0cakap5gg1rziq9vvs6s63il6s7";
				};
			};
			azemoh.theme-onedark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "azemoh";
					name = "theme-onedark";
					version = "0.6.0";
					sha256 = "0315x2hj2fc48n3dz7ijy5awrbzczxczj132ld8w9ffwvicjjpgb";
				};
			};
			usqlextpublisher.usql-vscode-ext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "usqlextpublisher";
					name = "usql-vscode-ext";
					version = "0.2.15";
					sha256 = "0f7v1nca8gykkn3g0rypi9amaq0bkx2xfdh23nyivlfabins9a3q";
				};
			};
			rocketseat.RocketseatReactJS = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rocketseat";
					name = "RocketseatReactJS";
					version = "3.0.2";
					sha256 = "1g2ckcqm7gziskgzxs3lwgz1wmqzrl70a1hy46hcyls74xm6f40v";
				};
			};
			Kasik96.swift = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Kasik96";
					name = "swift";
					version = "0.2.0";
					sha256 = "1skqdp97pvvg6f42wkqnqkscc8d6xvqp6lmmv7gh115mb27241gh";
				};
			};
			lolkush.quickstart = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lolkush";
					name = "quickstart";
					version = "0.1.0";
					sha256 = "18lar52j76a6bm4hhp1qkx18202m1mhy3y1dd07add6ii4wriy2v";
				};
			};
			fortran-lang.linter-gfortran = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fortran-lang";
					name = "linter-gfortran";
					version = "3.2.0";
					sha256 = "050lvn1rvmc1flx64h58hyrxw7fgvd7gcxp7xhddh6g5lrr1s22z";
				};
			};
			fabiospampinato.vscode-monokai-night = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fabiospampinato";
					name = "vscode-monokai-night";
					version = "1.6.0";
					sha256 = "0asq55nr1pw06dlgzxd8bj1n6n31h7sgfw5b846wvlplvd6mqkjy";
				};
			};
			kaiwood.endwise = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kaiwood";
					name = "endwise";
					version = "1.5.1";
					sha256 = "1dg096dnv3isyimp3r73ih25ya0yj0m1y9ryzrz40m0mbsk21mp4";
				};
			};
			goessner.mdmath = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "goessner";
					name = "mdmath";
					version = "2.7.4";
					sha256 = "1awgq9sfv09lrfmkj5qabp8wfxw3wjf1sbxlb3ql0wp7dr47la0c";
				};
			};
			Vue.vscode-typescript-vue-plugin = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Vue";
					name = "vscode-typescript-vue-plugin";
					version = "0.38.3";
					sha256 = "006rg8wn9rrrrb84sah976jnh452jv677rqynv2q8bwrlm5qsjwv";
				};
			};
			eventyret.bootstrap-4-cdn-snippet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eventyret";
					name = "bootstrap-4-cdn-snippet";
					version = "1.13.0";
					sha256 = "10fknx0lpqmb1qv3qxz391lw4pbqgwijk3gpyn7a07bf0praxhqr";
				};
			};
			gerane.Theme-FlatlandMonokai = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gerane";
					name = "Theme-FlatlandMonokai";
					version = "0.0.6";
					sha256 = "172q11973v6yrsq28kp537mnwljg2i8643z148556z1aw3flfpnd";
				};
			};
			mushan.vscode-paste-image = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mushan";
					name = "vscode-paste-image";
					version = "1.0.4";
					sha256 = "1wkplvrn31vly5gw35hlgpjpxgq3dzb16hz64xcf77bwcqfnpakb";
				};
			};
			espressif.esp-idf-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "espressif";
					name = "esp-idf-extension";
					version = "1.4.0";
					sha256 = "1255m52wbb6y2i8jzy33nj9inxlc76lfb4dcjrj87jf6pd0ndriw";
				};
			};
			ms-dynamics-smb.al = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-dynamics-smb";
					name = "al";
					version = "9.3.646020";
					sha256 = "07krghy0wnpw08f7dv5859k0zgfgdph425yp9i23cpzrnf5gx0v7";
				};
			};
			docsmsft.docs-yaml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "docsmsft";
					name = "docs-yaml";
					version = "0.2.8";
					sha256 = "0723k2wpmc3vy0s127gpgx5bipi9c29pg78dxrhzmvzhpb033w2q";
				};
			};
			dgileadi.java-decompiler = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dgileadi";
					name = "java-decompiler";
					version = "0.0.3";
					sha256 = "0mwja5nbql411lqrzjj1anggb5wdwcz24wd6q61m36c8bcgcx5sn";
				};
			};
			mrmlnc.vscode-duplicate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-duplicate";
					version = "1.2.1";
					sha256 = "1iz9nh19xw3d2c2h0c46dy4ps4gxchaa7spjjgckkc6cg9vxy3cq";
				};
			};
			ms-kubernetes-tools.vscode-aks-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-kubernetes-tools";
					name = "vscode-aks-tools";
					version = "1.2.0";
					sha256 = "0r99wf8aksk8lmaqb19kl6iyhqs845076a9wv795kwc70s28v2f5";
				};
			};
			bierner.lit-html = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "lit-html";
					version = "1.11.1";
					sha256 = "1qpkxri9ja4lsq7ga99vlg13byfpr5pkh5252wmlfank73mgrpkc";
				};
			};
			rocketseat.RocketseatReactNative = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rocketseat";
					name = "RocketseatReactNative";
					version = "3.0.1";
					sha256 = "17nz124d1a4gb5z4clkhkl00pa7khm23a9gpi65kb7m5vjxysg5m";
				};
			};
			alexdima.copy-relative-path = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alexdima";
					name = "copy-relative-path";
					version = "0.0.2";
					sha256 = "06g601n9d6wyyiz659w60phgm011gn9jj5fy0gf5wpi2bljk3vcn";
				};
			};
			jawandarajbir.react-vscode-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jawandarajbir";
					name = "react-vscode-extension-pack";
					version = "0.5.0";
					sha256 = "0z7c4v9r9jfhgc14ikwdwkciyj00rry3x947r5kn9fkpad07nk45";
				};
			};
			hridoy.rails-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hridoy";
					name = "rails-snippets";
					version = "1.0.8";
					sha256 = "0q3sw1i8qsm0czm359kgfjqksn928hclsbfgwrqqbcvi2037ya1r";
				};
			};
			gencer.html-slim-scss-css-class-completion = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gencer";
					name = "html-slim-scss-css-class-completion";
					version = "1.7.8";
					sha256 = "18qws35qvnl0ahk5sxh4mzkw0ib788y1l97ijmpjszs0cd4bfsa6";
				};
			};
			lkytal.FlatUI = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lkytal";
					name = "FlatUI";
					version = "1.4.9";
					sha256 = "1lkqrd89b0srwskpxirk25x88yczalh64hnvjcsn97h16q5r9v4y";
				};
			};
			thebarkman.vscode-djaneiro = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "thebarkman";
					name = "vscode-djaneiro";
					version = "1.4.2";
					sha256 = "04k9w4gsx3m7kd7mscnywb1ywv4bvzczcxsnb5r1zv5bdmvdfamz";
				};
			};
			adrianwilczynski.namespace = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "namespace";
					version = "1.1.2";
					sha256 = "11wdk9mg8q9qj2q1q44z2agwlnv3p7vg9g35jbkp5fakv37bxbfl";
				};
			};
			doggy8088.netcore-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "doggy8088";
					name = "netcore-snippets";
					version = "3.15.2";
					sha256 = "0zlnv14f907kbzigrs9paan1x4g2qg0lrr8cvjx7wcb3m50zi3m7";
				};
			};
			andys8.jest-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "andys8";
					name = "jest-snippets";
					version = "1.8.0";
					sha256 = "1kmghmrzmj96r1lxjqi6dvhd5l2vnb06infn0yklf00jpg7l1dfh";
				};
			};
			jakob101.RelativePath = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jakob101";
					name = "RelativePath";
					version = "1.5.0";
					sha256 = "1fjna46j3i5vl0jy4z2hrj8nwdzfkds86pp0w8cnkvnhq5cxc6kz";
				};
			};
			l7ssha.tag-inserter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "l7ssha";
					name = "tag-inserter";
					version = "1.4.0";
					sha256 = "11x4gb7j4i3cnc00fwaqi4w39jcj8gyfm55xrbhs5agsl4miqas3";
				};
			};
			jamesmaj.easy-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jamesmaj";
					name = "easy-icons";
					version = "0.3.1";
					sha256 = "09k3d0ww47yc1y3qvf813w1sqg03sq1y5kdnhlixigsvngslm9a4";
				};
			};
			spook.easysass = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "spook";
					name = "easysass";
					version = "0.0.6";
					sha256 = "16x1qv2ycn4gj94wqckhl4lp86sm5sns95h1dy5sdrsvdf8i09r1";
				};
			};
			shaharkazaz.git-merger = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shaharkazaz";
					name = "git-merger";
					version = "0.4.1";
					sha256 = "1xdialj07nwr907x1jdm00fqk38hkvs9jr2qv5jfm71dc5jsfvh4";
				};
			};
			DSKWRK.vscode-generate-getter-setter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DSKWRK";
					name = "vscode-generate-getter-setter";
					version = "0.5.0";
					sha256 = "08cjs82v8n95yld3lkykh9hyydmhack8yfiggw55ykjsrhpjynak";
				};
			};
			ms-dotnettools.vscode-dotnet-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-dotnettools";
					name = "vscode-dotnet-pack";
					version = "1.0.8";
					sha256 = "1c4n29rlhpwkdjbw5avbchvpnszd0sx3sg08r69sj79qllll02kf";
				};
			};
			AdamCaviness.theme-monokai-dark-soda = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AdamCaviness";
					name = "theme-monokai-dark-soda";
					version = "1.0.0";
					sha256 = "0w2189ysfh9kdmzgx138v11q2ybjpyg5mzf7wpyqpss9mb25375b";
				};
			};
			yamajyn.commandlist = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yamajyn";
					name = "commandlist";
					version = "1.0.5";
					sha256 = "0xwl8my3bmnyimfwhylg4idjw6p5kpbijzz9sr5na3xp5hqcb2x1";
				};
			};
			uctakeoff.vscode-counter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "uctakeoff";
					name = "vscode-counter";
					version = "3.0.5";
					sha256 = "0iqrmcbcwaygjisj96ayyxaxjwwbmg7y1kk6p0svw0k438m1icgw";
				};
			};
			SimonSiefke.svg-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SimonSiefke";
					name = "svg-preview";
					version = "2.8.3";
					sha256 = "0b3c8fb837qk2hs881l0lna8q0a85h2naymf1plf3jm4r7a5x1c4";
				};
			};
			krizzdewizz.refactorix = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "krizzdewizz";
					name = "refactorix";
					version = "0.3.6";
					sha256 = "1a88pgrdiv2z8q4x289v627zwx4yakpj1vlp6lw3rrj7lqcfmx7l";
				};
			};
			mrmlnc.vscode-less = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-less";
					version = "0.6.3";
					sha256 = "0ijlr397816ffkn2p8zc7i7yfbm524p89lmmhbc1hzybxa1nn309";
				};
			};
			qufiwefefwoyn.inline-sql-syntax = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "qufiwefefwoyn";
					name = "inline-sql-syntax";
					version = "2.15.0";
					sha256 = "0h8nybkym47cfmqcpm2fxiwlfsksra4y1hyk7qmi3k64rbs0rl9f";
				};
			};
			hridoy.jquery-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hridoy";
					name = "jquery-snippets";
					version = "1.0.0";
					sha256 = "0gda0wgn8gv1ilcmsd5nh8jlsg2pprfsqlib854nr5ygznrzj14n";
				};
			};
			blanu.vscode-styled-jsx = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "blanu";
					name = "vscode-styled-jsx";
					version = "2.1.1";
					sha256 = "1iglwy5dj933jbh5sq9cgcb2mdvmmjs2anc54dz4xg325yx4px5f";
				};
			};
			JakeWilson.vscode-picture = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JakeWilson";
					name = "vscode-picture";
					version = "1.0.0";
					sha256 = "0v98cai5qv1r5z7vnnapvidzx3aww01s2d2q5k04frn26iajyl3p";
				};
			};
			dunstontc.dark-plus-syntax = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dunstontc";
					name = "dark-plus-syntax";
					version = "0.2.8";
					sha256 = "0pfjlhwvhqm0698ar7mf3xz61xq480bcmjy5wi7ca3rzgkwiv75a";
				};
			};
			tushortz.pygame-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tushortz";
					name = "pygame-snippets";
					version = "0.0.1";
					sha256 = "1d5fdk6zc3jf2ggp3h5fd1ah14d4l44nylipspkl135ngm6cmkl5";
				};
			};
			Tobermory.es6-string-html = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tobermory";
					name = "es6-string-html";
					version = "2.12.0";
					sha256 = "15ln026zzcpdvhssq8g9kv10vppxlshl4sf8zcyj0a8j92pyhavf";
				};
			};
			pucelle.vscode-css-navigation = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pucelle";
					name = "vscode-css-navigation";
					version = "1.13.3";
					sha256 = "1pl59fvlmaqgxyrs7jzalrxcw6j84x7b1v4am4z7s9wlcambasml";
				};
			};
			deerawan.vscode-dash = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "deerawan";
					name = "vscode-dash";
					version = "2.4.0";
					sha256 = "0bj3sris57r4nm8n9z9dxsriv23ym2sjq5b6b1608nadkbvgkab2";
				};
			};
			fantasytyx.tortoise-svn = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fantasytyx";
					name = "tortoise-svn";
					version = "0.1.1";
					sha256 = "17p3k0y22xmfaa7264yaf70jbs68kaacdaqkldfvvpk15mnq86a4";
				};
			};
			aws-scripting-guy.cform = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "aws-scripting-guy";
					name = "cform";
					version = "0.0.24";
					sha256 = "0rbjb64y6z36ndzspkph7nmdn16qwqf6crq0p2zmdqbxw3racwsz";
				};
			};
			alefragnani.pascal-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alefragnani";
					name = "pascal-formatter";
					version = "2.6.0";
					sha256 = "1a4gliny2rpc8xg6gb4kfbm59kqsl6pd4yik3i975260l3pmwrqy";
				};
			};
			shyykoserhiy.vscode-spotify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shyykoserhiy";
					name = "vscode-spotify";
					version = "3.2.1";
					sha256 = "14d68rcnjx4a20r0ps9g2aycv5myyhks5lpfz0syr2rxr4kd1vh6";
				};
			};
			kevinkyang.auto-comment-blocks = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kevinkyang";
					name = "auto-comment-blocks";
					version = "1.0.1";
					sha256 = "03f0x9npmkw7arshpd198qd0ria9dz63ljby4zx3z6b1p3sbl11b";
				};
			};
			Rubymaniac.vscode-paste-and-indent = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Rubymaniac";
					name = "vscode-paste-and-indent";
					version = "0.0.8";
					sha256 = "0fqwcvwq37ndms6vky8jjv0zliy6fpfkh8d9raq8hkinfxq6klgl";
				};
			};
			clarkyu.vscode-sql-beautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "clarkyu";
					name = "vscode-sql-beautify";
					version = "0.3.13";
					sha256 = "13x1b0qyyy3h70183j4p5jhxl4zmnfjqga3saikxcmw5gc573his";
				};
			};
			mdickin.markdown-shortcuts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mdickin";
					name = "markdown-shortcuts";
					version = "0.12.0";
					sha256 = "1fx7dx2qkiqwq58vd74rrwazbpkhq6i5h74hkpjgz0xcir7yfc56";
				};
			};
			shanoor.vscode-nginx = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shanoor";
					name = "vscode-nginx";
					version = "0.6.0";
					sha256 = "038clpjp6csb5i1yg7xf0z1p6f198caxlypicskmpxdsdry52fqy";
				};
			};
			TomiTurtiainen.rf-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "TomiTurtiainen";
					name = "rf-intellisense";
					version = "2.8.0";
					sha256 = "15iznlbrzww7jqyqfn625vidcqxfags4c6rdbz5dr4d3a4sqcg9x";
				};
			};
			Hyzeta.vscode-theme-github-light = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Hyzeta";
					name = "vscode-theme-github-light";
					version = "7.14.2";
					sha256 = "0d2iphmr0iqzhkk9f8g8k3z1af9i1n536kmpns67b9jmn8d5pdql";
				};
			};
			erd0s.terraform-autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "erd0s";
					name = "terraform-autocomplete";
					version = "0.0.8";
					sha256 = "15a7s6hipsx3zi5nzhar3maj7d7x4mb1104l18j1mlda6czza2kh";
				};
			};
			Wscats.vue = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Wscats";
					name = "vue";
					version = "1.0.26";
					sha256 = "1qg59i61j1rn4dgcq4981mpvbi5pdcj40yi1z7hjz8n9g8vhcycn";
				};
			};
			mtxr.sqltools-driver-sqlite = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mtxr";
					name = "sqltools-driver-sqlite";
					version = "0.2.0";
					sha256 = "0icwc6a6krqsanx60xar2j5760khljy1wsvdwxcbfc4xjp4l8dhw";
				};
			};
			doggy8088.angular-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "doggy8088";
					name = "angular-extension-pack";
					version = "13.1.0";
					sha256 = "1k3619ic2j45v54xgqrdhqsvks1yj80mv4zj5jv62fh7g9nk4d9r";
				};
			};
			danielpinto8zz6.c-cpp-project-generator = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "danielpinto8zz6";
					name = "c-cpp-project-generator";
					version = "1.2.4";
					sha256 = "0a5nycrj6s3c1bpw72i1q5a4wac2b7smzhbdgyfwfqhlz3j4h1qh";
				};
			};
			toba.vsfire = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "toba";
					name = "vsfire";
					version = "1.4.1";
					sha256 = "0sdghqqzkfjr29d22v0g6xbv7n5gvmsybcmgnf2zkbl7azvhr4bd";
				};
			};
			walter-ribeiro.full-react-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "walter-ribeiro";
					name = "full-react-snippets";
					version = "1.4.2";
					sha256 = "1574z5x3rcxv6z5cpb1bhwkn4lpjkqsw8bgmmpxc4gj0rn8b6kyc";
				};
			};
			patcx.vscode-nuget-gallery = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "patcx";
					name = "vscode-nuget-gallery";
					version = "0.0.24";
					sha256 = "1gcg9j5318wc7c362iandkjk9im5nzfqaip3zqaxvwrl4wly6ada";
				};
			};
			ms-vscode.js-atom-grammar = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "js-atom-grammar";
					version = "0.1.14";
					sha256 = "15js4b051ldzyzbfjk0z2kz87nda5l4dw367wmh6566170zc4zdl";
				};
			};
			amlovey.shaderlabvscodefree = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "amlovey";
					name = "shaderlabvscodefree";
					version = "1.3.0";
					sha256 = "1rq8xf5v7lq6dvh5wy4vir3d6wf5hqikmbrpy68ablyzf135sm6n";
				};
			};
			herrherrmann.angular-bootstrap = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "herrherrmann";
					name = "angular-bootstrap";
					version = "4.0.9";
					sha256 = "1h8vb35s7hmx8qrhqba99f374wz01x4qgib8nyl8x2pgavb8hw4p";
				};
			};
			glenn2223.live-sass = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "glenn2223";
					name = "live-sass";
					version = "5.4.0";
					sha256 = "0y4vqngcd8z66lvplwdw8whfmsnyfgijja6in7sggc8m15r69qs4";
				};
			};
			chuckjonas.apex-pmd = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "chuckjonas";
					name = "apex-pmd";
					version = "0.5.9";
					sha256 = "14xcls3b49q5mw5lrkvfq68z9v91c7n5jxvy59mr7wiksz8srsq3";
				};
			};
			ryanluker.vscode-coverage-gutters = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ryanluker";
					name = "vscode-coverage-gutters";
					version = "2.10.1";
					sha256 = "1svkd9b8n7j1p2sw7wp9xa58ikni8hhdj40zjjzqagvw1j98kaf5";
				};
			};
			marcelovelasquez.flutter-tree = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marcelovelasquez";
					name = "flutter-tree";
					version = "1.0.0";
					sha256 = "08glv02b5d5f4jfdfddg62jvdzscinl2jhsb7gpz36rxrbp0f17s";
				};
			};
			brandonfowler.exe-runner = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "brandonfowler";
					name = "exe-runner";
					version = "0.2.1";
					sha256 = "0zkpz9z5gfsxjsrl9kxcf107pv4bf8yfz204ija2gv088x459svh";
				};
			};
			NativeScript.nativescript = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "NativeScript";
					name = "nativescript";
					version = "0.12.3";
					sha256 = "19pbclrkxbiv7pi687ablvx4jpfnhh54xy30pcq59s16dmcw4h6b";
				};
			};
			glitchbl.laravel-create-view = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "glitchbl";
					name = "laravel-create-view";
					version = "0.0.6";
					sha256 = "08j2yvfvrwlsbgyym70871cxbay9lgy3fynhq0lps9ky23kyk08h";
				};
			};
			walkme.HTML5-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "walkme";
					name = "HTML5-extension-pack";
					version = "1.0.0";
					sha256 = "1p5fyjs7vp2n5369560b4bkqlp3lsphsz3yw9dz897icyhp93zxx";
				};
			};
			hex-ci.stylelint-plus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hex-ci";
					name = "stylelint-plus";
					version = "0.56.6";
					sha256 = "1jzb4v40i94gl1j6637zqv1yv7f7md186vawxyz9dwcs692n3wrv";
				};
			};
			vsciot-vscode.azure-iot-edge = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsciot-vscode";
					name = "azure-iot-edge";
					version = "1.25.9";
					sha256 = "0s4xl0rla7sl0a32j5f18rdfwp2xpi76jc7amykd8vpbjqg8q2kg";
				};
			};
			Yummygum.city-lights-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Yummygum";
					name = "city-lights-theme";
					version = "1.1.8";
					sha256 = "09hkg5mlfh9xql5wwbk2r6wll7qbwz8g504gsai1byai6n6w067k";
				};
			};
			P-de-Jong.vscode-html-scss = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "P-de-Jong";
					name = "vscode-html-scss";
					version = "0.0.42";
					sha256 = "1hhxdc3zzjmfrf9xq9bxmy0kxl2yhw3i67grhyai41fk9ilzs74d";
				};
			};
			naoray.laravel-goto-components = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "naoray";
					name = "laravel-goto-components";
					version = "1.2.0";
					sha256 = "0srzp32qyza9mn56c7gabwdgbv8b1pn9r2fvwb2bqxlznyy00fyh";
				};
			};
			ChandZhang.wechat-snippet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ChandZhang";
					name = "wechat-snippet";
					version = "0.4.11";
					sha256 = "17q8h5ml33add64nmfmj9wcpn25xb0s8dlcyj3i7p3nxaxhjbsrc";
				};
			};
			discountry.react-redux-react-router-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "discountry";
					name = "react-redux-react-router-snippets";
					version = "0.4.29";
					sha256 = "1gki225p83l41nbc9pf71m90hv44c3bz0893dd30bhas49bzkgai";
				};
			};
			slevesque.vscode-zipexplorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "slevesque";
					name = "vscode-zipexplorer";
					version = "0.3.1";
					sha256 = "0y21f5lmllaa5ljfksrzgvlbp4mcvk5rz7q6djdc8gygln5wn64l";
				};
			};
			linyang95.php-symbols = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "linyang95";
					name = "php-symbols";
					version = "2.1.0";
					sha256 = "0kcsa17z0fb9hcn6v0jhyp09cb2j20mrsa22pkx8fh3ib6qfr5iw";
				};
			};
			yandeu.five-server = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yandeu";
					name = "five-server";
					version = "0.1.5";
					sha256 = "0rcsb6shp1sjkfd33ifvsgbvm7jw8yg9qlmgvcq3ccqw42wn338q";
				};
			};
			obenjiro.arrr = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "obenjiro";
					name = "arrr";
					version = "0.1.3";
					sha256 = "1d86f761ci5y641wf8sfldaylkzsa9llnczd5k965psgrbksfhlx";
				};
			};
			oleg-shilo.cs-script = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oleg-shilo";
					name = "cs-script";
					version = "2.1.0";
					sha256 = "1z07qwwqz0vpfiwimql0h6b6vg99ybgv0y4gs612qsyg8ffrwbb6";
				};
			};
			svipas.prettier-plus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "svipas";
					name = "prettier-plus";
					version = "4.2.2";
					sha256 = "1smmhkrwmfgf112av0sz79rwfcbmk5zpzdkf1y2bvzq8pzhvjarj";
				};
			};
			BazelBuild.vscode-bazel = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "BazelBuild";
					name = "vscode-bazel";
					version = "0.5.0";
					sha256 = "0gjf42xjhzwbncd6c8p7c60m44bkhk2kcpa3qjg2vr619p0i5514";
				};
			};
			IHunte.laravel-blade-wrapper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "IHunte";
					name = "laravel-blade-wrapper";
					version = "1.0.1";
					sha256 = "16gdpi1rh1lb5yfmaciq2plcfhc41s6shy1wxh96ddw6y3mg0ihk";
				};
			};
			Thavarajan.ionic2 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Thavarajan";
					name = "ionic2";
					version = "3.0.2";
					sha256 = "07zxagcx2qv2xvlkykh9i8sk38qlvbm0c86x1i0wlakvsfs7w7pn";
				};
			};
			adrianwilczynski.asp-net-core-switcher = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "asp-net-core-switcher";
					version = "2.0.2";
					sha256 = "0m9gj4shi7q2q5v31lag8jljssk8m2f13a9q64n6w36xz4nq249r";
				};
			};
			uloco.theme-bluloco-dark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "uloco";
					name = "theme-bluloco-dark";
					version = "3.6.0";
					sha256 = "08n754yj7vrrng5ai799d3gw3lp5nc8vijjn0gkbjc6x0x9rm305";
				};
			};
			nickdemayo.vscode-json-editor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nickdemayo";
					name = "vscode-json-editor";
					version = "0.3.0";
					sha256 = "160blmm22j2dsr2ms4b33jvdqnh94hcakvcwhhsyjqxld2x951ri";
				};
			};
			sldobri.bunker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sldobri";
					name = "bunker";
					version = "1.1.6";
					sha256 = "1151ys590yiyshyvvgj3ifhpwhb5ypka2bbcmr9m1cdyw420w1fh";
				};
			};
			PrimaFuture.open-php-html-js-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "PrimaFuture";
					name = "open-php-html-js-in-browser";
					version = "2.0.1";
					sha256 = "0cmgzairifp4fc00rhg91db6db02blqcfgqphfrv3klzdnwk20kr";
				};
			};
			be5invis.toml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "be5invis";
					name = "toml";
					version = "0.6.0";
					sha256 = "0q8blfihawmqfbyy68lv932mdac1miph5cs8i6d0w8wh9jwdnkna";
				};
			};
			cweijan.vscode-office = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cweijan";
					name = "vscode-office";
					version = "2.6.5";
					sha256 = "14grplvc6h4rb9xxdnn9wj3xj759snbmal2cipmd2zn0jyzm07l4";
				};
			};
			bbenoist.vagrant = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bbenoist";
					name = "vagrant";
					version = "0.5.0";
					sha256 = "1fkrv6ncw752n5ni7c3p9hd7l9f2msw7rgxw07x2wigp3zd5y06x";
				};
			};
			joaompinto.vscode-graphviz = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "joaompinto";
					name = "vscode-graphviz";
					version = "0.0.6";
					sha256 = "17z5zgr8l94mj8dgqxwsrpixnkz0778fp1g4rxc7i56wb1zbik3w";
				};
			};
			henriiik.docker-linter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "henriiik";
					name = "docker-linter";
					version = "0.5.0";
					sha256 = "0icmvv4cdwg8gl9q9n7hbql7l8aabi3bp40lh2h716r31vqkzfhi";
				};
			};
			ajhyndman.jslint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ajhyndman";
					name = "jslint";
					version = "1.2.1";
					sha256 = "1fshj2c7iq6lsxwsbpgnjl0bkgl3ckliphd7q6xhdi73xsghql1n";
				};
			};
			golang.go-nightly = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "golang";
					name = "go-nightly";
					version = "2022.6.2921";
					sha256 = "0sgx7h11nlrshpyq5hs4hsilwg4fiirvqiklc3xh5516lmbxkhxa";
				};
			};
			akhail.save-typing = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "akhail";
					name = "save-typing";
					version = "0.1.0";
					sha256 = "0m2bi6gjlfazwzd8rngjx8bmivl4214p9wbq3fc8pf0nq8z9xmr6";
				};
			};
			tungvn.wordpress-snippet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tungvn";
					name = "wordpress-snippet";
					version = "1.1.5";
					sha256 = "0ng75snm646bhw14ndr9n856pbk9svckgvw8inbki4jrsmf9vgm9";
				};
			};
			sandcastle.vscode-open = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sandcastle";
					name = "vscode-open";
					version = "0.1.0";
					sha256 = "0jb4qgvwxykz676kk8ichyn2k04a5ijbn5clq89hjq0rbhlp968b";
				};
			};
			plorefice.devicetree = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "plorefice";
					name = "devicetree";
					version = "0.1.1";
					sha256 = "0yfz6rgmh9j9bq7ahcjxphj74jd8rnnlg355vffdy8xfqdirxp5r";
				};
			};
			marlon407.code-groovy = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marlon407";
					name = "code-groovy";
					version = "0.1.2";
					sha256 = "1gs0p7hwfzbzh6wpy0xlr4cn74pjj03aa1lcwdvnxpjb4sd7hd7j";
				};
			};
			Endormi._2077-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Endormi";
					name = "2077-theme";
					version = "1.5.3";
					sha256 = "193307f01vsrcc5bdmidzb5j2qganzwbsv6lra24dadky9lav356";
				};
			};
			trixnz.vscode-lua = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "trixnz";
					name = "vscode-lua";
					version = "0.12.4";
					sha256 = "16048ivy600v7jvi3fbwlsn22l4fva0r79lnjmr0igjw16qx5rbj";
				};
			};
			coderfee.vscode-wxml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "coderfee";
					name = "vscode-wxml";
					version = "0.1.9";
					sha256 = "1z4mc0ya6407g0c7ancn06wfgffi166wysmxdw9vbhm1p8w6lpd6";
				};
			};
			rodrigovallades.es7-react-js-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rodrigovallades";
					name = "es7-react-js-snippets";
					version = "1.9.3";
					sha256 = "18rqlbhy7ql5r7rln1cd3ba2p52g5x5rsplmsyc3c8jly6nk6ikc";
				};
			};
			ithildir.java-properties = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ithildir";
					name = "java-properties";
					version = "0.0.2";
					sha256 = "1gl73frgl37xyf4nnr1qhx5l3x4k4pxxs8z6rx1k4960ssxbn653";
				};
			};
			numso.prettier-standard-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "numso";
					name = "prettier-standard-vscode";
					version = "0.9.2";
					sha256 = "07b3phm95zak4crn00imf3rjjnqqc9b1a5i8l2h0iff7av6zrhkq";
				};
			};
			_076923.python-image-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "076923";
					name = "python-image-preview";
					version = "0.1.2";
					sha256 = "1ywwvswv7cdjl33r65cjq5hds2fyllcxniqmmidp5nkgg0bzkpsz";
				};
			};
			Nimda.deepdark-material = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Nimda";
					name = "deepdark-material";
					version = "3.3.0";
					sha256 = "100pgsyvgwl0b7gb2hc37a5dn1j6x74z5gk8whx7avamnmh5khq5";
				};
			};
			premparihar.gotestexplorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "premparihar";
					name = "gotestexplorer";
					version = "0.1.13";
					sha256 = "0pzhalampn22m2rxzx6siy10zjc7iwzp8p7m5bp02v1x47brk2h8";
				};
			};
			dcasella.monokai-plusplus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dcasella";
					name = "monokai-plusplus";
					version = "2.0.4";
					sha256 = "1s5bl1m8v5rsxca7lkpn8jin8i08mp3x587v53mc5hsdq06zjl8h";
				};
			};
			tamasfe.even-better-toml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tamasfe";
					name = "even-better-toml";
					version = "0.16.4";
					sha256 = "0pxrky5v9d9zxbfya7cyv8m2y260x9dmlinm4ybpxnw9j9v5xvfh";
				};
			};
			ms-azuretools.vscode-azurestaticwebapps = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-azurestaticwebapps";
					version = "0.11.2";
					sha256 = "0v7pgv6b25x2sy1cpgq7sd8ni6wyl90xa9f3j5pgfhxkwh7rvyss";
				};
			};
			johnpapa.Angular1 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "johnpapa";
					name = "Angular1";
					version = "0.2.1";
					sha256 = "131lvpj3y9bgd7193lrpayadv3i8sznxz3s70rzrhh0p78drb071";
				};
			};
			msyrus.go-doc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "msyrus";
					name = "go-doc";
					version = "1.0.1";
					sha256 = "0xmy0v20yjrcg6qh3w3x0qamqmjd19146fl15rvx3ihini72660s";
				};
			};
			rafaelmaiolla.remote-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rafaelmaiolla";
					name = "remote-vscode";
					version = "1.1.0";
					sha256 = "0czq5phkjdbwkya9fkczywzq98jw0l9b1x8sllbm3j04d9mfbh0p";
				};
			};
			ms-pyright.pyright = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-pyright";
					name = "pyright";
					version = "1.1.257";
					sha256 = "0ipxy4n0xfzd9p8cgwi0g6njsyfr1nmbl36hsdfqyfpjvbacfpgc";
				};
			};
			yoyo930021.vuter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yoyo930021";
					name = "vuter";
					version = "0.1.2";
					sha256 = "12ivzmlgdnmpzvdvh6l0lzfg5q7xjjhw35kzy0slxbinh7dyacwd";
				};
			};
			Perkovec.emoji = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Perkovec";
					name = "emoji";
					version = "1.0.1";
					sha256 = "16lbhmikiq7amfsbcbyds5ckbm5zl1bbr8dvm2aiqacpnxfscwmw";
				};
			};
			eyhn.vscode-vibrancy = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eyhn";
					name = "vscode-vibrancy";
					version = "1.0.16";
					sha256 = "0yb2wba03ivkzbgibiwypkw0r4zxy84h7kw447dh1dmbykln1xir";
				};
			};
			raynigon.nginx-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "raynigon";
					name = "nginx-formatter";
					version = "0.0.13";
					sha256 = "0hm3zfbw0235s04aib9f2rjhl8j5n8xjvmw8ccxn2y7bgnhnks55";
				};
			};
			robberphex.php-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "robberphex";
					name = "php-debug";
					version = "1.14.0";
					sha256 = "0si7qxzm0kqay9zjr809p4y2k2xharzpblz0g42y0y38ai801kns";
				};
			};
			fabioz.vscode-pydev = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fabioz";
					name = "vscode-pydev";
					version = "0.3.0";
					sha256 = "1ijil203dd7j1mdy2fm5q4440vq1nikmnvrv12ndmrk3dx0dsssd";
				};
			};
			koppt.vscode-view-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "koppt";
					name = "vscode-view-in-browser";
					version = "1.0.5";
					sha256 = "0vyc1n1sq0rv1746w9jmah2mcx2y2j1i77n5aygbwhc8yrxil2y1";
				};
			};
			_766b.go-outliner = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "766b";
					name = "go-outliner";
					version = "0.1.20";
					sha256 = "0jx398zx82d3kbkkwfv5bhblafbz1b7pjwwxiha6c2p50890bpyb";
				};
			};
			vuetifyjs.vuetify-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vuetifyjs";
					name = "vuetify-vscode";
					version = "0.2.0";
					sha256 = "0v8qrmdd8diq2bl19y5g4bi7mkwyy9whkn72jg6ha7inx179rv9q";
				};
			};
			max-SS.cyberpunk = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "max-SS";
					name = "cyberpunk";
					version = "1.2.14";
					sha256 = "0q41rql3zvdbp79vwr2bgmvfn6hsjazk5ciw0hxg67d72xhh15dp";
				};
			};
			PKief.material-product-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "PKief";
					name = "material-product-icons";
					version = "1.3.0";
					sha256 = "1my2rvyvvrn61jl1g2hnjgpsma1c7czr6ip4y1006d9ghqsc9h3k";
				};
			};
			kriegalex.vscode-cudacpp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kriegalex";
					name = "vscode-cudacpp";
					version = "0.1.1";
					sha256 = "00qkx97sk2savwpi0szc5hyjr3pwp1b809pcklynrcqnp5rj2zn1";
				};
			};
			danielehrhardt.ionic3-vs-ionView-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "danielehrhardt";
					name = "ionic3-vs-ionView-snippets";
					version = "1.0.2";
					sha256 = "0yvk3z4p5lvk6vf509dq13ci3bxlsdxrnwfhbza464f16v724gl8";
				};
			};
			jeremyrajan.webpack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jeremyrajan";
					name = "webpack";
					version = "2.2.0";
					sha256 = "1z0jljlgipc2bp0xknvg5v6i0vmqf7mp9qlnwwsgxlfz8kq5pg6r";
				};
			};
			qinjia.seti-icons = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "qinjia";
					name = "seti-icons";
					version = "0.1.3";
					sha256 = "1apnhq45dc7iflk15nxvqg1yvhbml75zqv02bdrii5k97909xqxs";
				};
			};
			asvetliakov.vscode-neovim = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "asvetliakov";
					name = "vscode-neovim";
					version = "0.0.87";
					sha256 = "1glrkksd7ch5jrvh9fdz6hnq4kj9d5vcflx5x9cdqif3vi1381qm";
				};
			};
			MarinhoBrandao.Angular2Tests = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MarinhoBrandao";
					name = "Angular2Tests";
					version = "0.7.3";
					sha256 = "17zgxrix5s828jbdhvgsl21vs8zyr90gkzkiz4ifhr67ivw4xkr5";
				};
			};
			mrorz.language-gettext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrorz";
					name = "language-gettext";
					version = "0.2.0";
					sha256 = "0q17d4k6bj8d4sbr5ip54vm06ydgcv8ajgd7hhi3vmjwfsdk8ryy";
				};
			};
			Gruntfuggly.activitusbar = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Gruntfuggly";
					name = "activitusbar";
					version = "0.0.46";
					sha256 = "1q5pflr9g2g2nkbfgqx1b8j9wl2y0z1pjvg899jz08aahbs034dh";
				};
			};
			spences10.VBA = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "spences10";
					name = "VBA";
					version = "1.7.1";
					sha256 = "01b8kxwp4zcy3n69xrrq08pcza70kjjvsjln91lq1awgwl4yzjy8";
				};
			};
			mblode.pretty-formatter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mblode";
					name = "pretty-formatter";
					version = "0.2.2";
					sha256 = "1kdcxdvccf1fhg8lr8zwi5v7l2ja02p1kxq871jgakq2y42fclpy";
				};
			};
			adamvoss.vscode-languagetool = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adamvoss";
					name = "vscode-languagetool";
					version = "3.8.0";
					sha256 = "1p6cjb61509id66lynfshzdsvw43acnrhsm0h0g56zr65gz8nn9i";
				};
			};
			CraigMaslowski.erb = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "CraigMaslowski";
					name = "erb";
					version = "0.0.1";
					sha256 = "17abqiwvm75bcmz565w55612s4nmixfw4pgw558m0ampq53ln3wd";
				};
			};
			bbenoist.shell = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bbenoist";
					name = "shell";
					version = "0.3.0";
					sha256 = "1xcakvn0djb9950c27fwvsicm5s82imrw8jmycgzl7dsyr8vi3f4";
				};
			};
			capaj.vscode-standardjs-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "capaj";
					name = "vscode-standardjs-snippets";
					version = "0.9.0";
					sha256 = "13mjg9zhbsj1bkmvq8ljpazcvqqzyy2633vkwjh6mj1mhai18f7n";
				};
			};
			doggy8088.netcore-extension-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "doggy8088";
					name = "netcore-extension-pack";
					version = "1.7.0";
					sha256 = "1hc5sna6xw6adpyfvm57w26hm5g4qnlakn0vyl142gwiwp8r3k5s";
				};
			};
			michelemelluso.gitignore = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "michelemelluso";
					name = "gitignore";
					version = "1.0.1";
					sha256 = "0gx7prknsw3hbhycgzsv6mr1qclmh2mjz8c184xha5a8iihvpml9";
				};
			};
			ipedrazas.kubernetes-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ipedrazas";
					name = "kubernetes-snippets";
					version = "0.1.9";
					sha256 = "0gf1m9vppcsdbvdsx2k0a9xj2cfqbbm8b4iw7v8xgn4y2k6w8lq6";
				};
			};
			s-nlf-fh.glassit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "s-nlf-fh";
					name = "glassit";
					version = "0.2.4";
					sha256 = "01n9ls29g7sq5g5g47p6v74aghdxmn9dr83rdrn5y0m95hm22sk2";
				};
			};
			george-alisson.html-preview-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "george-alisson";
					name = "html-preview-vscode";
					version = "0.2.5";
					sha256 = "1n41xb22cqpn0058qksyx1xp00zjx5gf8a497lhsnlain4sf2j6n";
				};
			};
			ronnidc.nunjucks = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ronnidc";
					name = "nunjucks";
					version = "0.3.1";
					sha256 = "0dlsri0dcligjz3x1ddpjhyvna6dmdswhb86c9k73y22r12fd1zd";
				};
			};
			bierner.markdown-yaml-preamble = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "markdown-yaml-preamble";
					version = "0.1.0";
					sha256 = "1xlb6dvrsy2sp92lax1nq01xcrax1nm256ns9b4vvkq7p4njpqp5";
				};
			};
			secanis.jenkinsfile-support = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "secanis";
					name = "jenkinsfile-support";
					version = "0.1.0";
					sha256 = "0qijj78ndy6vw2qalcjaj80n8ba2cv2fkrc2a0dqn01bsp385nml";
				};
			};
			MikeBovenlander.formate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MikeBovenlander";
					name = "formate";
					version = "1.2.1";
					sha256 = "1rjdsm7msv3gkn5s9xh3b8s1fcjpwzdkr9s81rbflhlczkkqxhag";
				};
			};
			Meezilla.json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Meezilla";
					name = "json";
					version = "0.0.1";
					sha256 = "1lkxs3wgy41ckimxgx2v1520qh7q73qv3yb9hl785wy7w1irhl30";
				};
			};
			openhab.openhab = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "openhab";
					name = "openhab";
					version = "1.0.0";
					sha256 = "0zcd9dl6c1nhjqqgzdyf4rqllqwffak9vxxjcrmnfady9y5rw9wh";
				};
			};
			febean.vue-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "febean";
					name = "vue-format";
					version = "0.1.8";
					sha256 = "1g1a3yahsi24iib2a40jm7v5dsp7snxf10fsywvxbfb851c2r2ws";
				};
			};
			moshfeu.compare-folders = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "moshfeu";
					name = "compare-folders";
					version = "0.22.2";
					sha256 = "0s1hng46a51w2whzsllamv6lnqp18y16qki36396vv5757pgz4zb";
				};
			};
			kaysonwu.cpptask = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kaysonwu";
					name = "cpptask";
					version = "0.0.1";
					sha256 = "0k4qqn6qpq410nnjfxpwrzgcsxm50v8kx3bjg4cil7m0dg4miw1j";
				};
			};
			piotrpalarz.vscode-gitignore-generator = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "piotrpalarz";
					name = "vscode-gitignore-generator";
					version = "1.0.3";
					sha256 = "0yf3h7hd2vx8ic8fgmphad2al3d9w7a9vxis63nwd4fphn9678vs";
				};
			};
			whtouche.vscode-js-console-utils = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "whtouche";
					name = "vscode-js-console-utils";
					version = "0.7.0";
					sha256 = "0gvs4b8d2pr9408c6228iishd6vh2dw8gh28kxdbbcp15pf55vhi";
				};
			};
			haaaad.ansible = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "haaaad";
					name = "ansible";
					version = "0.2.8";
					sha256 = "0zbnx07i9hqh348inbxwf660hih6jdwwz11l3rd1adi1v0hmcw8z";
				};
			};
			coolbear.systemd-unit-file = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "coolbear";
					name = "systemd-unit-file";
					version = "1.0.6";
					sha256 = "0sc0zsdnxi4wfdlmaqwb6k2qc21dgwx6ipvri36x7agk7m8m4736";
				};
			};
			HansUXdev.bootstrap5-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HansUXdev";
					name = "bootstrap5-snippets";
					version = "1.2.5";
					sha256 = "084pb5kbhr5jilmjyi80ya323029z3q6cj7gaakvxsxg00zhm83k";
				};
			};
			localizely.flutter-intl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "localizely";
					name = "flutter-intl";
					version = "1.18.2";
					sha256 = "18k0v56q7m3g3i6i2qmd68b28krfx005dm13rx3nn4d8awyxjyc9";
				};
			};
			sainnhe.gruvbox-material = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sainnhe";
					name = "gruvbox-material";
					version = "6.5.0";
					sha256 = "1r9kgwrh6jjp8i6aa07prhrb398d5isf9ics4wmdbvd6k0gnzf8n";
				};
			};
			unbug.codelf = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "unbug";
					name = "codelf";
					version = "11.7.0";
					sha256 = "0y07hzgxw5cf8alwm2siqfl6cb8myzsim5cqs4975vs2dnbjvrlc";
				};
			};
			diz.ecsstractor-port = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "diz";
					name = "ecsstractor-port";
					version = "0.0.3";
					sha256 = "135my70z6al5dkhqdjrz6fka5166qdkxww7sqbg8mwwbyrc7bxzb";
				};
			};
			njqdev.vscode-python-typehint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "njqdev";
					name = "vscode-python-typehint";
					version = "1.4.1";
					sha256 = "04rbaj55wqd8v58rhs2qz8gb5ln5abx1y7qlnhd0vvnypka7y2i3";
				};
			};
			bibhasdn.git-easy = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bibhasdn";
					name = "git-easy";
					version = "1.11.0";
					sha256 = "0vqs2gmx35is06bb0ddfwv58cknlryl55b89i1awi9039q617y6v";
				};
			};
			neilding.language-liquid = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "neilding";
					name = "language-liquid";
					version = "0.1.1";
					sha256 = "0jy4hrhrb2kcqmjzp3ys3a915dskl0hbndhpfslsfypjk5cxky6b";
				};
			};
			AnbuselvanRocky.bootstrap5-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "AnbuselvanRocky";
					name = "bootstrap5-vscode";
					version = "0.3.0";
					sha256 = "1baj88k13lz39grxz852zz8gqwm34wca74mxijmcd3c0fb4bd14v";
				};
			};
			sensourceinc.vscode-sql-beautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sensourceinc";
					name = "vscode-sql-beautify";
					version = "0.0.4";
					sha256 = "10a8776nqz2zziddx8kldj8d7g0ixjqncyrz41wfnv22fxn455pw";
				};
			};
			redhat.vscode-microprofile = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-microprofile";
					version = "0.4.0";
					sha256 = "0885ai9k35n9f7minv5ic18bawikb4vrrnh8mjcgrlf0j765g03s";
				};
			};
			wayou.vscode-icons-mac = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wayou";
					name = "vscode-icons-mac";
					version = "7.25.3";
					sha256 = "0wjx93nkj8n9pc8a7h08aqdj7ar2bghfs95dn30h5kch49biwy79";
				};
			};
			WallabyJs.wallaby-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "WallabyJs";
					name = "wallaby-vscode";
					version = "1.0.344";
					sha256 = "1rsh3p57vv51kivyz665h7cvxb88sy45nhdkjdmmbravax1qyxfw";
				};
			};
			ironmansoftware.powershellprotools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ironmansoftware";
					name = "powershellprotools";
					version = "2022.6.0";
					sha256 = "0zas2gvwsjdvgbzzhydhshqkfm280yqqpk6g1ica5whkg1aq3n4l";
				};
			};
			trinm1709.dracula-theme-from-intellij = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "trinm1709";
					name = "dracula-theme-from-intellij";
					version = "0.3.0";
					sha256 = "1yiwxl2xb47vhmppzf63h6clxc4vmnmrc15b154m08n72j2gzrh4";
				};
			};
			NicolasVuillamy.vscode-groovy-lint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "NicolasVuillamy";
					name = "vscode-groovy-lint";
					version = "1.9.0";
					sha256 = "1lhdyzmd9nnlxmv465kl1lz4zbzharmllafzjpkhz9rcsb9q5cv5";
				};
			};
			alefragnani.numbered-bookmarks = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "alefragnani";
					name = "numbered-bookmarks";
					version = "8.3.0";
					sha256 = "0xmn7li96y24xi3q3bc039xv0zphgmvpc0286slckmp24h0z1k9n";
				};
			};
			emeraldwalk.RunOnSave = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "emeraldwalk";
					name = "RunOnSave";
					version = "0.2.0";
					sha256 = "1n7pblhbkkmznq9nanybfkwskibvfi4a11l9wvdpqd1765nvvycw";
				};
			};
			geequlim.godot-tools = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "geequlim";
					name = "godot-tools";
					version = "1.3.1";
					sha256 = "143mjd9g2wgvljgad5zsb6yvgpklknja3q8qjvi1h40vdw6h54n0";
				};
			};
			phplasma.csv-to-table = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "phplasma";
					name = "csv-to-table";
					version = "1.4.0";
					sha256 = "0c6dk3vjxnl96z7slc4sak7m6lss5dfxl0mfm7mcmhccflbr485s";
				};
			};
			tal7aouy.theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tal7aouy";
					name = "theme";
					version = "2.3.0";
					sha256 = "0wwljdjw1iikdzbpl6mi7jdrh6jy2rx3xw9l3sahnyyszl8j336m";
				};
			};
			heybourn.headwind = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "heybourn";
					name = "headwind";
					version = "1.7.0";
					sha256 = "127f383bkzyyngbw76aqldx62dfvswai3i5q3idkfhc95fhijyy9";
				};
			};
			Tyriar.shell-launcher = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tyriar";
					name = "shell-launcher";
					version = "0.4.1";
					sha256 = "0ws4nd7zr0n8kyb07dvknsnzzf53za35l4im1wq24p766jiyd0c4";
				};
			};
			craigthomas.supersharp = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "craigthomas";
					name = "supersharp";
					version = "0.1.4";
					sha256 = "1d4vjg35458fif9f36rdsbl0k2rdlb0ml3k6rwmgzd1j18yryngb";
				};
			};
			ms-vscode.js-debug-companion = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "js-debug-companion";
					version = "1.0.18";
					sha256 = "0c2a9p3w5gb5w144qyfddlfnv9ksyyvn5bh9vviqzj2jyhsf37ml";
				};
			};
			NG-42.ng-fortytwo-vscode-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "NG-42";
					name = "ng-fortytwo-vscode-extension";
					version = "0.0.9";
					sha256 = "0ylj9wpi105cs9gaynmk1g9qsnlrkjp4jg8d9w0g16whazs2sd5q";
				};
			};
			sainoba.px-to-rem = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sainoba";
					name = "px-to-rem";
					version = "1.3.1";
					sha256 = "0v2sbbzyck3s0ym4ma1b93g8aw9rcrz885k97vksp1g4pdcy1nir";
				};
			};
			oscarcs.dart-syntax-highlighting-only = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oscarcs";
					name = "dart-syntax-highlighting-only";
					version = "1.0.1";
					sha256 = "0pywqj2bdfhj67wwyl0f8mcv066mn8wvm7w3cf6ypvch6a0xshc8";
				};
			};
			ajshort.latex-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ajshort";
					name = "latex-preview";
					version = "0.5.1";
					sha256 = "1zn79cszs4l6y9f8svxpy9p4r01grj2msbw1pqyg178i7md1rc0w";
				};
			};
			overtrue.miniapp-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "overtrue";
					name = "miniapp-helper";
					version = "1.0.3";
					sha256 = "0r4m0w6bb6zsy2max58g6xa3lym0vfcpjn7sq8k3shiywr9hsbkg";
				};
			};
			redhat.ansible = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "ansible";
					version = "0.10.0";
					sha256 = "0fhhyvzn6vcyhlmb5w5vnis3qyn96h8id7fjcp3pv3j3yg9fnw3i";
				};
			};
			rahulsahay.Csharp-ASPNETCore = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rahulsahay";
					name = "Csharp-ASPNETCore";
					version = "1.11.0";
					sha256 = "0mf1vxbydqhrczchy1ir3wkywmkmbnkj1qdpkyx428badlmak1mn";
				};
			};
			neikeq.godot-csharp-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "neikeq";
					name = "godot-csharp-vscode";
					version = "0.2.1";
					sha256 = "04gm1k1kh6aa3yzrbjhby10ddqs8bmsikiii6syg78syhzxhzfxh";
				};
			};
			redhat.vscode-quarkus = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-quarkus";
					version = "1.10.0";
					sha256 = "0f9lp6chnajz1ncjjfyqi5rff0hxc6d4xi9rs52ynz71q04fyzjv";
				};
			};
			tomphilbin.gruvbox-themes = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "tomphilbin";
					name = "gruvbox-themes";
					version = "1.0.0";
					sha256 = "0xykf120j27s0bmbqj8grxc79dzkh4aclgrpp1jz5kkm39400z0f";
				};
			};
			mrmlnc.vscode-csscomb = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-csscomb";
					version = "5.3.2";
					sha256 = "0gg3hxiqfx5mc4z2jvcziswnn8bpk7l815fkg1bm7hli7s28q76q";
				};
			};
			cnyballk.wxml-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "cnyballk";
					name = "wxml-vscode";
					version = "0.1.2";
					sha256 = "0yqm0gchxjzjjgf9i6f9y0fa5870dw1zbkc1czxhlhzgw9zkynbx";
				};
			};
			HashiCorp.HCL = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "HashiCorp";
					name = "HCL";
					version = "0.2.0";
					sha256 = "08rfjd5imy8vkkgr9g2hsaqckmxxg8k2z9isghdlwnhwa6fq3hx2";
				};
			};
			jgw9617.ionic2-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jgw9617";
					name = "ionic2-vscode";
					version = "1.0.0";
					sha256 = "0sja05b1sac4jlvzksfl0a6hy375pqrifb98v022hxnndpw383wp";
				};
			};
			ACharLuk.easy-cpp-projects = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ACharLuk";
					name = "easy-cpp-projects";
					version = "2.0.0";
					sha256 = "1jnaj2b19pf9a5gvbv7v3awcc9y8323fwkqln28xlg4xxf1rjp73";
				};
			};
			kakumei.php-xdebug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kakumei";
					name = "php-xdebug";
					version = "0.0.7";
					sha256 = "0n2xnrca8bbs5b96mqdvpn9z8c25h63apkg1xqlvsbm1z9krmnqj";
				};
			};
			paulmolluzzo.convert-css-in-js = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "paulmolluzzo";
					name = "convert-css-in-js";
					version = "1.1.3";
					sha256 = "051w68ljhs7xkrb082zl6sdglljz5h9rnjkyzczwvs5i7dnak6hg";
				};
			};
			Lokalise.i18n-ally = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Lokalise";
					name = "i18n-ally";
					version = "2.8.1";
					sha256 = "0m2r3rflb6yx1y8gh9r8b7j8ia6iswhq2q4kxn7z6v8f6y5bndd0";
				};
			};
			debian001.app-migrator = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "debian001";
					name = "app-migrator";
					version = "0.0.6";
					sha256 = "0dqrdawnzxdh4kw01w8y10s72rbp53zs83kcfxfgk86mg39pjwqk";
				};
			};
			ceciljacob.code-plus-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ceciljacob";
					name = "code-plus-theme";
					version = "1.0.0";
					sha256 = "1zjg9czn530hk5dj4icslwdls816f53gwiyjxyqij65di0p574gp";
				};
			};
			Mikhail-Arkhipov.r = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Mikhail-Arkhipov";
					name = "r";
					version = "0.0.28";
					sha256 = "1kalrfi86xbncvx914n3kcjif33g42j42h0igwbcjb4bdwzqrzly";
				};
			};
			xshrim.txt-syntax = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "xshrim";
					name = "txt-syntax";
					version = "0.2.0";
					sha256 = "09pfvbrv0083pxyakrfrmp4djnrvx0x96wya0ajbsrabfygjh6g0";
				};
			};
			BattleBas.kivy-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "BattleBas";
					name = "kivy-vscode";
					version = "0.5.5";
					sha256 = "1nwhy6f9k8vmhhgnj20dlwgvbnp662s844a7b4njywcb281zbiy1";
				};
			};
			bierner.github-markdown-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bierner";
					name = "github-markdown-preview";
					version = "0.3.0";
					sha256 = "124vsg5jxa90j3mssxi18nb3wn6fji6b0mnnkasa89rgx3jfb5pf";
				};
			};
			KuanHulio.discord = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "KuanHulio";
					name = "discord";
					version = "0.0.6";
					sha256 = "1dqrvqybq28vjhq0490w8hdg89i14fy4zn7yg8nkfzqyfiw0zid4";
				};
			};
			sachittandukar.laravel-5-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sachittandukar";
					name = "laravel-5-snippets";
					version = "2.0.1";
					sha256 = "1w9fmhlk6r2bikblhn81f0vzs431z84d9my73j0z9mkybqql0bf9";
				};
			};
			TheNouillet.symfony-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "TheNouillet";
					name = "symfony-vscode";
					version = "1.0.2";
					sha256 = "0qb99mkisykkzb0lbf4r94l677m408bkmxirmz4xjcha1gkchifw";
				};
			};
			ElemeFE.vscode-element-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ElemeFE";
					name = "vscode-element-helper";
					version = "0.5.6";
					sha256 = "08iil5vm6j9l9hr0zdxc3jnpqzcyza0wz8ym3wadrkwljkm973i6";
				};
			};
			bajdzis.vscode-twig-pack = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bajdzis";
					name = "vscode-twig-pack";
					version = "1.1.0";
					sha256 = "041qkrl5s55hdn579sqbn34iisk3fsaimnqxfman3isvq5xzigdc";
				};
			};
			manasxx.background-cover = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "manasxx";
					name = "background-cover";
					version = "2.3.0";
					sha256 = "0pl66qhnrv3sbl5ijcb742d65z5f33hnswh33r6jr74adkkl7ghj";
				};
			};
			dbankier.vscode-instant-markdown = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dbankier";
					name = "vscode-instant-markdown";
					version = "1.4.7";
					sha256 = "1xbx4nhkj35lhlriicnkbqk16mh8nrh9la35lw1yl10pgcrb2k4y";
				};
			};
			sissel.shopify-liquid = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sissel";
					name = "shopify-liquid";
					version = "2.3.0";
					sha256 = "1ckzl19w6h288kqzzhb5zjfmrbvi1h3gvnffccmzmq4s08na772b";
				};
			};
			groksrc.ruby = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "groksrc";
					name = "ruby";
					version = "0.1.0";
					sha256 = "1nbihym14hikqrcc53bqmpwd5m4kbq63kn9aqp25czyim1h37f96";
				};
			};
			bpruitt-goddard.mermaid-markdown-syntax-highlighting = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bpruitt-goddard";
					name = "mermaid-markdown-syntax-highlighting";
					version = "1.3.0";
					sha256 = "000hs0p36ifaqvhffyx880ik1vj1b3zgrby4l1fmfsljdq0qvkla";
				};
			};
			vortizhe.simple-ruby-erb = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vortizhe";
					name = "simple-ruby-erb";
					version = "0.2.1";
					sha256 = "1g7gig85kbnwfy5fx9n7m9bi3z1ga3cnc1gfq8g74l0nlkijz6i5";
				};
			};
			marp-team.marp-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marp-team";
					name = "marp-vscode";
					version = "2.1.0";
					sha256 = "0x0wssq2nmllxkw8zlbf2mfbhd5gpp7pwxw920kz2ai7x0kk8k3s";
				};
			};
			circlecodesolution.ccs-flutter-color = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "circlecodesolution";
					name = "ccs-flutter-color";
					version = "1.0.2";
					sha256 = "0wv4zvx200pbd2cj4g1qma45045a8459bzrwcklmya22r7316k2r";
				};
			};
			dawhite.mustache = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dawhite";
					name = "mustache";
					version = "1.1.1";
					sha256 = "1j8qn5grg8v3n3v66d8c77slwpdr130xzpv06z1wp2bmxhqsck1y";
				};
			};
			ms-azuretools.vscode-apimanagement = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-azuretools";
					name = "vscode-apimanagement";
					version = "1.0.5";
					sha256 = "16wp866n66h4m68s1nhmfmz6lmgivbs3zmlki0bzg79v216d5azq";
				};
			};
			zhoufeng.pyqt-integration = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "zhoufeng";
					name = "pyqt-integration";
					version = "0.2.0";
					sha256 = "099d7smcdgn6br5xbwii5cdzrzx6j82n3j9qhfynfm984l88pf30";
				};
			};
			vsls-contrib.gistfs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsls-contrib";
					name = "gistfs";
					version = "0.4.1";
					sha256 = "0681f3l0zr31vp2fdj12fw95p705k2206mv7i50q3qvfkv7n5pkf";
				};
			};
			dcortes92.FreeMarker = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dcortes92";
					name = "FreeMarker";
					version = "0.0.9";
					sha256 = "1hkarlnknx3byinpxch9xzxyrys1l7d6fvagmcyb9r5bsw8x9hhh";
				};
			};
			gamedilong.anes = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gamedilong";
					name = "anes";
					version = "0.0.2";
					sha256 = "0vmcszp8cl39rq1z49zbgrjf0wb071fkrjd8n01g71iichad9ydc";
				};
			};
			iocave.monkey-patch = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "iocave";
					name = "monkey-patch";
					version = "0.1.18";
					sha256 = "1mbp7p9d9dny5161majplzi1pm6ym7jxkxw7m8nc775pzr9in0i1";
				};
			};
			MehediDracula.php-constructor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "MehediDracula";
					name = "php-constructor";
					version = "0.1.2";
					sha256 = "1zvr8qkmx2gj6y3lqjw7iyhxwkzwsc0rmvzkafjvqm7ch09g4fby";
				};
			};
			timothymclane.react-redux-es6-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "timothymclane";
					name = "react-redux-es6-snippets";
					version = "2.1.0";
					sha256 = "1a65z4p0zpv5q01j0iipq0dxyb3crli7s4kly0kal3zm036wv1mf";
				};
			};
			ivory-lab.jenkinsfile-support = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ivory-lab";
					name = "jenkinsfile-support";
					version = "1.1.0";
					sha256 = "0m520k8czk2r1rxx0dn0sw1i0k89ji1s8yr3y9i8bqc0ay6bsrba";
				};
			};
			joaompinto.asciidoctor-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "joaompinto";
					name = "asciidoctor-vscode";
					version = "2.8.0";
					sha256 = "06nx627fik3c3x4gsq01rj0v59ckd4byvxffwmmigy3q2ljzsp0x";
				};
			};
			lehni.vscode-fix-checksums = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lehni";
					name = "vscode-fix-checksums";
					version = "1.1.0";
					sha256 = "08yzqp2fs6rgdmjcfkwx03glkwrb6byl1dm7pkdfsi95d4i5v55w";
				};
			};
			pkosta2005.heroku-command = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pkosta2005";
					name = "heroku-command";
					version = "0.0.8";
					sha256 = "13xy8gdsl6ap1h4j5hq6pnjvhc6dip9yilgh3qvqilzv4dmn49k4";
				};
			};
			marcostazi.VS-code-vagrantfile = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marcostazi";
					name = "VS-code-vagrantfile";
					version = "0.0.7";
					sha256 = "0mpdsc8gzf19mgf90rfba90klgvijjddigaj4f9hqjmkvlrbghzg";
				};
			};
			natqe.reload = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "natqe";
					name = "reload";
					version = "0.0.6";
					sha256 = "05a10gf7y50i546ld34drinx2zpa48bhpgs0nvrvw982gf9lncbd";
				};
			};
			sallar.vscode-duotone-dark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sallar";
					name = "vscode-duotone-dark";
					version = "0.3.3";
					sha256 = "1d7s49j2m4ga590iqnhb0ayafrz9f9lkl3warp8a1898767a1wrq";
				};
			};
			sasa.vscode-sass-format = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sasa";
					name = "vscode-sass-format";
					version = "1.1.7";
					sha256 = "1hzfjj272gmq1y9pf210g59q6n7z6ldc7ankjqw409kcpv11s12y";
				};
			};
			ahmadalli.vscode-nginx-conf = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ahmadalli";
					name = "vscode-nginx-conf";
					version = "0.1.3";
					sha256 = "10z0him4kl9q6h1nip7d3dp9nv0a1dkh3x6zqc6nilfw959v3358";
				};
			};
			yhpnoraa.beauty = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yhpnoraa";
					name = "beauty";
					version = "0.0.2";
					sha256 = "1pcawlnaxgjw47ci13q3vailnin2hz6qsgly82wfip9r7l3flghg";
				};
			};
			ardenivanov.svelte-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ardenivanov";
					name = "svelte-intellisense";
					version = "0.7.1";
					sha256 = "1g28sq3wgpsyq7kbd742pg02r0hyp8vwa2rgvx0kyy021hr8c27w";
				};
			};
			maximetinu.identical-sublime-monokai-csharp-theme-colorizer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "maximetinu";
					name = "identical-sublime-monokai-csharp-theme-colorizer";
					version = "1.2.2";
					sha256 = "1qm24dscd1rzzbd42i0rn57m1chq28m64my8wm73gvlw7as5575d";
				};
			};
			docsmsft.docs-images = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "docsmsft";
					name = "docs-images";
					version = "0.0.10";
					sha256 = "1zgf34cfjyyig5015nibvs9mac36mzyipiy3r4blm3w5ai5z6iv3";
				};
			};
			DivyanshuAgrawal.competitive-programming-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "DivyanshuAgrawal";
					name = "competitive-programming-helper";
					version = "5.9.2";
					sha256 = "09jcbph149nysp159plmpwsa70czml0zxs6752zidm26bia66ig6";
				};
			};
			pkosta2006.rxjs-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pkosta2006";
					name = "rxjs-snippets";
					version = "0.0.2";
					sha256 = "1rgr6501vywfdx8x64gkiabb2psqfddw6kh9fnw63y68da7nm7ic";
				};
			};
			adrianwilczynski.terminal-commands = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "terminal-commands";
					version = "1.0.5";
					sha256 = "0z745915gqs50mc6zg2pq44q3zmpwifmcli945dyvaj1v26bi4gg";
				};
			};
			karunamurti.haml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "karunamurti";
					name = "haml";
					version = "1.4.1";
					sha256 = "123cwfajakkg2pr0z4v289fzzlhwbxx9dvb5bjc32l3pzvbhq4gv";
				};
			};
			doggy8088.quicktype-refresh = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "doggy8088";
					name = "quicktype-refresh";
					version = "1.0.2";
					sha256 = "0dajny68w2qs10rkdm084rb5nn29m2a3sxkgwms9d80nyig7ajdp";
				};
			};
			SS.element-ui-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "SS";
					name = "element-ui-snippets";
					version = "0.7.2";
					sha256 = "0lzi8zlm9cc9m4yb4ir77fjd15gpq185yg0gndr2w4qmdv6avdky";
				};
			};
			ms-vscode.Theme-TomorrowKit = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode";
					name = "Theme-TomorrowKit";
					version = "0.1.4";
					sha256 = "0rrfpwsf2v8mra102b9wjg3wzwpxjlsk0p75g748my54cqjk1ad9";
				};
			};
			dzhavat.css-flexbox-cheatsheet = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dzhavat";
					name = "css-flexbox-cheatsheet";
					version = "3.3.1";
					sha256 = "10x1cm9cbd9s2i4b4l59jaj7cirpls1x3j8547h77sp2l6r4yl22";
				};
			};
			gerane.Theme-Dark-Dracula = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gerane";
					name = "Theme-Dark-Dracula";
					version = "0.0.5";
					sha256 = "044c7s9d1phsw6b1iyb2kyrcad8ka10x7bbng74n6w1ipm9vdqp8";
				};
			};
			oliversturm.fix-json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "oliversturm";
					name = "fix-json";
					version = "0.1.2";
					sha256 = "08ngcxdg1gy900vxrz7h9ywq1ggl7gs1f14s9lql3v6xryv25c4p";
				};
			};
			hangxingliu.vscode-nginx-conf-hint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hangxingliu";
					name = "vscode-nginx-conf-hint";
					version = "0.3.0";
					sha256 = "17rrgbpa0ads9jkf1757srdmqacpn4nclwx9n7g9p4m3s3gszamp";
				};
			};
			ev3dev.ev3dev-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ev3dev";
					name = "ev3dev-browser";
					version = "1.2.0";
					sha256 = "05hsrbj7a1wgcrl38wb0kjgxv8ygmra1ijvixzwannfxq6rn0siq";
				};
			};
			rctay.karma-problem-matcher = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rctay";
					name = "karma-problem-matcher";
					version = "1.0.1";
					sha256 = "0q3jy6jpn1i3qqyg85416abz0iqacmd4n7wrw3wqzz3cy7ii3z6a";
				};
			};
			spmeesseman.vscode-taskexplorer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "spmeesseman";
					name = "vscode-taskexplorer";
					version = "2.9.1";
					sha256 = "02fc7vny4a5fslllxwzwn10jar4yw2j3ic4p0yjacb2vyfsp1zwv";
				};
			};
			adrianwilczynski.add-reference = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "add-reference";
					version = "1.0.2";
					sha256 = "07vmldl76i4h2igm48lsags0jcja7wip200z532s6cv34kf3b4ky";
				};
			};
			zhouronghui.propertylist = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "zhouronghui";
					name = "propertylist";
					version = "0.0.2";
					sha256 = "0g0kyivwvgym3gzx1ixgjr39y0g699p9n8sfvs8qz55cgsk5y6y9";
				};
			};
			lior-chamla.google-fonts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lior-chamla";
					name = "google-fonts";
					version = "0.0.1";
					sha256 = "17772rl3il3ksh86l483rfv7hayk038di6rxajxi9snb9lf0x0qw";
				};
			};
			kddejong.vscode-cfn-lint = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "kddejong";
					name = "vscode-cfn-lint";
					version = "0.21.0";
					sha256 = "1x7w97a34mbjx5pndlil7dhicjv2w0n58b60g5ibpvxlvy49grr2";
				};
			};
			znck.vue = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "znck";
					name = "vue";
					version = "0.11.4";
					sha256 = "131shs44v3rn00462056sb41fq4mm4bfv07va63nhbpflbmbw2f7";
				};
			};
			rafa-acioly.laravel-helpers = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rafa-acioly";
					name = "laravel-helpers";
					version = "0.2.2";
					sha256 = "1hgs96hz9xwgi7vk4zbifzwlwilmr9br6k2ssblb7cr7mf6ys029";
				};
			};
			ms-vscode-remote.remote-ssh-edit-nightly = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ms-vscode-remote";
					name = "remote-ssh-edit-nightly";
					version = "2021.12.12420";
					sha256 = "1rkhhn6x4ixgafdc3javv0bpyfgy57xhsjv3wgv58kl17sxkn15l";
				};
			};
			shamanu4.django-intellisense = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "shamanu4";
					name = "django-intellisense";
					version = "0.0.2";
					sha256 = "146irhf1mfzawl4kbmx9zzs8rb9yvi6wr83mm8hhh3f0ihkdxdrn";
				};
			};
			darkriszty.markdown-table-prettify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "darkriszty";
					name = "markdown-table-prettify";
					version = "3.6.0";
					sha256 = "08hhcnj8xs9kmwdli0vg87az40g05sj4qv1jvijcrywqchsf550m";
				};
			};
			mark-tucker.aws-cli-configure = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mark-tucker";
					name = "aws-cli-configure";
					version = "0.3.0";
					sha256 = "0qfn4fnlymsm4nls2c5h0caf5hxiysfy67r8266vxllan8qaifvp";
				};
			};
			puorc.awesome-vhdl = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "puorc";
					name = "awesome-vhdl";
					version = "0.0.1";
					sha256 = "1h55jahz8rpwyx14r3rqx9lsb00vzcj42pr95n4hhyipkbr3sc9z";
				};
			};
			Remisa.shellman = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Remisa";
					name = "shellman";
					version = "5.6.0";
					sha256 = "1j6jcdd1kc08k3d0vywvrsmml49kpafvqy6bpbx1agaxyjd8sjd1";
				};
			};
			waldo.crs-al-language-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "waldo";
					name = "crs-al-language-extension";
					version = "1.5.17";
					sha256 = "1fjhqhha1fry61mvswm9dbgh4mqh6g0mzi69dwxw74y2phd7h260";
				};
			};
			intellsmi.comment-translate = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "intellsmi";
					name = "comment-translate";
					version = "2.2.4";
					sha256 = "099jkkz5j9gg0wq8kk6ndvnjhilkfwrba5m8p9cqmwkgri4sbac3";
				};
			};
			RedVanWorkshop.explorer-exclude-vscode-extension = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "RedVanWorkshop";
					name = "explorer-exclude-vscode-extension";
					version = "1.2.0";
					sha256 = "02cfkyk0b7giasc9l08a1cj51spvcqc9qmndc48k1yanm4xhzxf9";
				};
			};
			bengreenier.vscode-node-readme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "bengreenier";
					name = "vscode-node-readme";
					version = "3.0.2";
					sha256 = "0rc000x9b2p34rjg4nyqq1p93zr3n6nmy4mk5bw03yvl79hrm355";
				};
			};
			qwtel.sqlite-viewer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "qwtel";
					name = "sqlite-viewer";
					version = "0.2.0";
					sha256 = "0qfbmfci5xqvjwg3cy2qlq5wmfcfm9vzah38nnrvljg24ji0cirz";
				};
			};
			andrzejzwierzchowski.al-code-outline = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "andrzejzwierzchowski";
					name = "al-code-outline";
					version = "3.0.33";
					sha256 = "0k32lkrb9fh7s3j9rnqkvjasm05xw7dpyi26rmhag3a7fm9c4f02";
				};
			};
			freebroccolo.reasonml = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "freebroccolo";
					name = "reasonml";
					version = "1.0.38";
					sha256 = "1nay6qs9vcxd85ra4bv93gg3aqg3r2wmcnqmcsy9n8pg1ds1vngd";
				};
			};
			piyushvscode.nodejs-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "piyushvscode";
					name = "nodejs-snippets";
					version = "0.0.2";
					sha256 = "09shbvb519bgg2jc83kq7dh7bpg7kyy80spkd32wzxlr0wrxadrs";
				};
			};
			igress.python-coding-conventions = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "igress";
					name = "python-coding-conventions";
					version = "0.0.4";
					sha256 = "1jjny2n56gzgnsjwhnsgij8p2b0h7xkjdhkaq63q8jqqd7hpx3fh";
				};
			};
			akamud.vscode-caniuse = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "akamud";
					name = "vscode-caniuse";
					version = "0.5.4";
					sha256 = "1q1piyz0my8v6fp5rmvgnlhqk6wi3znzppv0vzc5alvzpsv9y0cw";
				};
			};
			helgardrichard.helium-icon-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "helgardrichard";
					name = "helium-icon-theme";
					version = "1.0.0";
					sha256 = "07p237ks6has034g5nm5mm4zjzcrfxbzfjwh4vig70nh6nwjj85r";
				};
			};
			maty.vscode-mocha-sidebar = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "maty";
					name = "vscode-mocha-sidebar";
					version = "0.22.2";
					sha256 = "1zdda7jqfz26zq5grg4109lk1lp59gx3srk46rviymyvsvpgbzbl";
				};
			};
			hyb1996.auto-js-vscodeext = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "hyb1996";
					name = "auto-js-vscodeext";
					version = "0.2.3";
					sha256 = "0rr9dncas1py2dwp086yrpv1by4wkdafn0kpy4y9mlxylavrvvc5";
				};
			};
			dahong.theme-bear = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "dahong";
					name = "theme-bear";
					version = "2.1.0";
					sha256 = "175g8azxyvg58im07ngf6n2x6dpkmd7mhfnsdncw4l52scpbqbgc";
				};
			};
			letmaik.git-tree-compare = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "letmaik";
					name = "git-tree-compare";
					version = "1.14.0";
					sha256 = "0sgvb4a0dpzlrbhcahsfcxgvcw3lgsjd8i98dk2qdx7wmj46xzaa";
				};
			};
			fnando.linter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "fnando";
					name = "linter";
					version = "0.0.11";
					sha256 = "0j79xaps9s1c7fp3xmk6mdwmjxsdsv9bz535maxh6xjyk117wsp3";
				};
			};
			seansassenrath.vscode-theme-superonedark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "seansassenrath";
					name = "vscode-theme-superonedark";
					version = "0.0.15";
					sha256 = "1gpq04w7xcskd904k2h0whcmnij84lamfsqrcyd6k0yn2c8mypb8";
				};
			};
			Janne252.fontawesome-autocomplete = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Janne252";
					name = "fontawesome-autocomplete";
					version = "1.3.1";
					sha256 = "02mksr0iharvps8vs12h7vsjhgc1yjad7h6vpiy11d8500iwf8gk";
				};
			};
			riazxrazor.html-to-jsx = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "riazxrazor";
					name = "html-to-jsx";
					version = "0.0.1";
					sha256 = "0mzri5bfay4balfbmrb5ls4qa0qak687zwcyanmw9s4sp8nlic7c";
				};
			};
			marqu3s.aurora-x = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "marqu3s";
					name = "aurora-x";
					version = "2.0.2";
					sha256 = "0kqmryxh3rmvb20f70l3czg7vlxx8a73jclypsfp78cssh4r6is5";
				};
			};
			iocave.customize-ui = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "iocave";
					name = "customize-ui";
					version = "0.1.61";
					sha256 = "00y4621ciibvhqyb6m5h60agh8x50n52rbw9ijlzwqk12f7bmhpn";
				};
			};
			mitchdenny.ecdc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mitchdenny";
					name = "ecdc";
					version = "1.8.0";
					sha256 = "11gc4qgqypbrcj33m4lx4xkcj8z7a41rby28iq091rj206gaarav";
				};
			};
			VignaeshRamA.sfdx-package-xml-generator = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "VignaeshRamA";
					name = "sfdx-package-xml-generator";
					version = "2.0.8";
					sha256 = "0v3gg8gg2dpx5jc0xr4hc7i4rz1v39y4xwwqfaga1xq9ip2ciyvy";
				};
			};
			andischerer.theme-atom-one-dark = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "andischerer";
					name = "theme-atom-one-dark";
					version = "0.0.1";
					sha256 = "1jsb8ihz8adpm66y7p0fgh29sxkhmjx3pdvp1qqf4qd6q8fn197n";
				};
			};
			GulajavaMinistudio.mayukaithemevsc = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "GulajavaMinistudio";
					name = "mayukaithemevsc";
					version = "3.2.3";
					sha256 = "1bcxpd7si0rrfnq012v325i3ns40dms2rgkgfqqnrq0n7l5c7wx0";
				};
			};
			ericadamski.carbon-now-sh = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ericadamski";
					name = "carbon-now-sh";
					version = "1.2.0";
					sha256 = "0an0vvxz63ckn65xf85yv8z9mzd9niwfl1nxmkhh6w5g5sskhllc";
				};
			};
			pgourlain.erlang = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "pgourlain";
					name = "erlang";
					version = "0.8.4";
					sha256 = "1jg5dxv38qvf26k0k51iz8jqsg6f1s08zkq3dfb6cdhvzkvsl6fd";
				};
			};
			gerane.Theme-azure = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gerane";
					name = "Theme-azure";
					version = "0.0.5";
					sha256 = "10338jg37ysabrhj4420hwkz0l0f3wp2xvs400hhbf6884gwf3jr";
				};
			};
			aksharpatel47.vscode-flutter-helper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "aksharpatel47";
					name = "vscode-flutter-helper";
					version = "0.2.5";
					sha256 = "0djv7khv4631kkdi1jysczmrj9zs8z0jpi7rnb1wi0df8qzxv0hd";
				};
			};
			jtlowe.vscode-icon-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jtlowe";
					name = "vscode-icon-theme";
					version = "1.6.6";
					sha256 = "1c441b1x1s37bm75vdbdhqmx13vpivnvwaqcga43qxd0h03327nc";
				};
			};
			nadako.vshaxe = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "nadako";
					name = "vshaxe";
					version = "2.24.0";
					sha256 = "0f2yclfdpq64gk559s5yiawcwlpkz537lp4lq7acgv3zpa3abr7l";
				};
			};
			mblode.twig-language = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mblode";
					name = "twig-language";
					version = "0.9.2";
					sha256 = "0qsiv1m1pd12jifw70lsnbdwhxw6w5y9b0f7f19dqyl5hnzd02hf";
				};
			};
			redhat.vscode-rsp-ui = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "redhat";
					name = "vscode-rsp-ui";
					version = "0.23.11";
					sha256 = "1mcxh67vxckmr49imgfqsgrhh0g1h0zb4qvczcxyhbzaqnc92fq6";
				};
			};
			matepek.vscode-catch2-test-adapter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "matepek";
					name = "vscode-catch2-test-adapter";
					version = "4.2.2";
					sha256 = "0rab84yc9yzhxhj8hbjmm17qijkqlm1ys5r9aybmixkn5x7h7p55";
				};
			};
			andyyaldoo.vscode-json = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "andyyaldoo";
					name = "vscode-json";
					version = "1.5.0";
					sha256 = "1ws6baddpggzzwwshkbrx0mba5nr0y9pyr8rl45d2p16q1nnp4kl";
				};
			};
			yinfei.luahelper = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "yinfei";
					name = "luahelper";
					version = "0.2.16";
					sha256 = "103nvcfg1lh86icrm7xllx9xjjybbq7vifl7zky9kahgj2yasnsb";
				};
			};
			peterj.proto = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "peterj";
					name = "proto";
					version = "0.0.2";
					sha256 = "04fzwdm7zywc2mja0j29ak7k8nzs15cfl4ixfhqp5dpi3z4l63lw";
				};
			};
			adrianwilczynski.user-secrets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "user-secrets";
					version = "2.0.1";
					sha256 = "0xsq8pk9vqwj7na0ykk7djqib9hn8p306fifv451svhcd8551iy0";
				};
			};
			trond-snekvik.simple-rst = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "trond-snekvik";
					name = "simple-rst";
					version = "1.5.2";
					sha256 = "1dq5bs419f6gjm4c30kwh4rjjkghq1j3zfb21zhqc314r55zypm5";
				};
			};
			codemooseus.vscode-devtools-for-chrome = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "codemooseus";
					name = "vscode-devtools-for-chrome";
					version = "0.0.7";
					sha256 = "1yykvpvw3c0ik1868w85x7yjy405p0bzlvc17jaasd893sk95jnq";
				};
			};
			jonkwheeler.styled-components-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jonkwheeler";
					name = "styled-components-snippets";
					version = "0.10.0";
					sha256 = "0xjjpbz35nz0zj209zp9n5wzhyqqv8lcviv2y6rqww8vdj51ks5d";
				};
			};
			lego-education.ev3-micropython = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "lego-education";
					name = "ev3-micropython";
					version = "2.0.0";
					sha256 = "0sdzrbd9rp8r7w1qlr8xbxzd2rirnk5kqi81q0sdi6r0mhpvphfm";
				};
			};
			danields761.dracula-theme-from-intellij-pythoned = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "danields761";
					name = "dracula-theme-from-intellij-pythoned";
					version = "0.1.4";
					sha256 = "1zqzhmpbyg9pdzqs6ydj5gib4z5lb877ndzdn5cq5vsgy2av8pi4";
				};
			};
			evan-buss.font-switcher = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "evan-buss";
					name = "font-switcher";
					version = "4.0.3";
					sha256 = "1n3i25r3rz2b2005frlwal9f7941749dbhwg8g9pd9g87lapmzpk";
				};
			};
			vsls-contrib.codetour = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsls-contrib";
					name = "codetour";
					version = "0.0.58";
					sha256 = "05hsi02h3qv98nfigrhmshbh8yvv76vs13f4vq7v5awgggi0ppj1";
				};
			};
			QassimFarid.ejs-language-support = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "QassimFarid";
					name = "ejs-language-support";
					version = "0.0.1";
					sha256 = "0v2xnjanvqqx1nzhfzjh2hhnmzvqfzg2c1yb0hb7d5zv0i4syj9g";
				};
			};
			rafamel.subtle-brackets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "rafamel";
					name = "subtle-brackets";
					version = "3.0.0";
					sha256 = "1wqwgjmbr8xr5k9jhpqyaz7j793h9vxbpf2rbwwg9fxj17wx9833";
				};
			};
			vsciot-vscode.vscode-iot-workbench = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "vsciot-vscode";
					name = "vscode-iot-workbench";
					version = "0.16.0";
					sha256 = "0vapnk5903r2w7a65w6ygmpc0jj8wqsmm2a8mxxysrd0qjzj684y";
				};
			};
			NicholasHsiang.vscode-vue2-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "NicholasHsiang";
					name = "vscode-vue2-snippets";
					version = "1.1.1";
					sha256 = "0lck3ksh37k4425gax29d7ci3hf1wq0xx57nj59pvvwryppaks31";
				};
			};
			benjamin-simmonds.pythoncpp-debug = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "benjamin-simmonds";
					name = "pythoncpp-debug";
					version = "0.2.18";
					sha256 = "1bf88fyz6v242dzi7qb9xjq3yb31hl5f62gwlqj26xc8s50xanl3";
				};
			};
			traBpUkciP.vscode-npm-scripts = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "traBpUkciP";
					name = "vscode-npm-scripts";
					version = "0.2.1";
					sha256 = "07dkkch8wl2s35q67m50v8i8265ngn78wrkh16ar61nhg9gz1z5h";
				};
			};
			igordvlpr.open-in-browser = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "igordvlpr";
					name = "open-in-browser";
					version = "1.0.2";
					sha256 = "1174rify25haa7mgr5dj8zkdpnvrp0kmwp91nmwxhgcfrisdls7a";
				};
			};
			karyfoundation.theme-karyfoundation-themes = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "karyfoundation";
					name = "theme-karyfoundation-themes";
					version = "27.0.0";
					sha256 = "0mdf5gqp8y5xm1nvwcvcd6r8vlbr20p2xkf9r1vyw5v7ih3kyh37";
				};
			};
			jumpinjackie.vscode-map-preview = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jumpinjackie";
					name = "vscode-map-preview";
					version = "0.5.9";
					sha256 = "0w88vpb77rm88prh7xfyylc95424wg7x5nc78xalwhsrlkmy67by";
				};
			};
			mrmlnc.vscode-attrs-sorter = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-attrs-sorter";
					version = "2.1.0";
					sha256 = "1gqrpqapvbrjr8v4zdc2xnx9faamarcjsmcq6hsp2lrm2hmzk0mb";
				};
			};
			isudox.vscode-jetbrains-keybindings = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "isudox";
					name = "vscode-jetbrains-keybindings";
					version = "0.1.9";
					sha256 = "0fb0m1r17lxk132m94gklxkr5y1pmnxgiafciaailsbqv9w3ms33";
				};
			};
			LeonardSSH.vscord = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "LeonardSSH";
					name = "vscord";
					version = "4.5.0";
					sha256 = "07vfcm2q0j1s7z4abcgncwl5xsgpyxxlcl7xbjg698qkipcvxmhn";
				};
			};
			ZixuanWang.linkerscript = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ZixuanWang";
					name = "linkerscript";
					version = "1.0.2";
					sha256 = "0rr5mz8g8myskgixiw76rwda8g955a1al8kk4s30b0byfaszia17";
				};
			};
			adamhartford.vscode-base64 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adamhartford";
					name = "vscode-base64";
					version = "0.1.0";
					sha256 = "037ih4wmh3gps0lk7bmv3l9c87p97ynishwcnakz27s7g65fbg9h";
				};
			};
			wongjn.php-sniffer = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "wongjn";
					name = "php-sniffer";
					version = "1.3.0";
					sha256 = "153pm5wf89x1sacdp2hlxbmj1lhfiwc6gl9fr02m8ngx2l4pbwbl";
				};
			};
			jeff-hykin.polacode-2019 = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "jeff-hykin";
					name = "polacode-2019";
					version = "0.5.2";
					sha256 = "1aszpnxjg44q3s4glh5rwfz0spd92p672ic3mll6mnskqk1ilwz1";
				};
			};
			Tyriar.terminal-tabs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Tyriar";
					name = "terminal-tabs";
					version = "0.2.1";
					sha256 = "1975nkbx1dc3psn2bw5rg6632s8hl5dafi4bqm83db9kv6zjvfl9";
				};
			};
			eiminsasete.apacheconf-snippets = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "eiminsasete";
					name = "apacheconf-snippets";
					version = "1.3.0";
					sha256 = "13kbvwm8r6kwhrzdkc9pxpyb5vn1myav84kaf9qb42kmc22s29a7";
				};
			};
			Mukundan.python-docs = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Mukundan";
					name = "python-docs";
					version = "0.8.3";
					sha256 = "0qxxcw2hmfhgx9spp7dyiriwpbjgfii2c06pmp3cdchfr5plqc13";
				};
			};
			gitpod.gitpod-remote-ssh = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "gitpod";
					name = "gitpod-remote-ssh";
					version = "0.0.32";
					sha256 = "0z988imfg3f55dkgl0ymack9xnim31jwfq0n4yx7w8iydbs39dxy";
				};
			};
			Gimly81.fortran = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "Gimly81";
					name = "fortran";
					version = "0.2.0";
					sha256 = "0qajhdlpp00vrlcv2xw79a3qvlw64zjzsrbj1bvvpj5hxkscd4px";
				};
			};
			planbcoding.vscode-react-refactor = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "planbcoding";
					name = "vscode-react-refactor";
					version = "1.1.3";
					sha256 = "18q4cah0mfn3rzswjll7z9k1p079fci5slardg7nlvbsrdn7wxjb";
				};
			};
			miguelsolorio.min-theme = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "miguelsolorio";
					name = "min-theme";
					version = "1.5.0";
					sha256 = "1ik4gj9yypjzaqfsg0awqkgqsid86hcxlv0h6pcnk3m6alxgspqc";
				};
			};
			JamesBirtles.svelte-vscode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JamesBirtles";
					name = "svelte-vscode";
					version = "0.9.3";
					sha256 = "0wfdp06hsx7j13k1nj63xs3pmp7zr6p96p2x45ikg3xrsvasghyn";
				};
			};
			mrmlnc.vscode-pugbeautify = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "mrmlnc";
					name = "vscode-pugbeautify";
					version = "1.0.2";
					sha256 = "00flqqnlpabzff201jc8labg5mbi6x3640i3f8n1na25jhfjq2fq";
				};
			};
			streetsidesoftware.code-spell-checker-portuguese-brazilian = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "streetsidesoftware";
					name = "code-spell-checker-portuguese-brazilian";
					version = "2.0.7";
					sha256 = "0rk3r61i1070p5c4ihfdb03rsjsr0zhyvfs88v9rrpdr5sbb3yhj";
				};
			};
			adrianwilczynski.csharp-to-typescript = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "adrianwilczynski";
					name = "csharp-to-typescript";
					version = "1.12.1";
					sha256 = "1z82kkc5y4cz4wlfj3h7xinal3035fag1qzy6rq6plq1sk0hmi7d";
				};
			};
			ionutvmi.reg = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "ionutvmi";
					name = "reg";
					version = "1.1.0";
					sha256 = "1by83l07x1n5gq2hqav6vsnk38ni7hmllzfhx1r33nhkyz5r29m5";
				};
			};
			roerohan.mongo-snippets-for-node-js = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "roerohan";
					name = "mongo-snippets-for-node-js";
					version = "1.3.12";
					sha256 = "15a9vqw29q2f4jvpwimp8kqvd722lxr4wrwwlknmvv8sxfgbm643";
				};
			};
			sbrink.elm = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "sbrink";
					name = "elm";
					version = "0.26.0";
					sha256 = "0lcjjq710lrarzswidi7yhiyfa96byi9qd146pzjmpxggkj2jmw5";
				};
			};
			JohnAaronNelson.ForceCode = buildVscodeMarketplaceExtension {
				mktplcRef = {
					publisher = "JohnAaronNelson";
					name = "ForceCode";
					version = "4.0.4";
					sha256 = "189g7xyrxljri2pzxnnvsnja7j0si5pzbzy4f4cznkrcm0hlkvx7";
				};
			};

		};
	});
}
