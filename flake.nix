{
	description = "VSCode and OpenVSX Extensions Collection For Nix";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils }:
	flake-utils.lib.eachDefaultSystem (system: let
		pkgs = import nixpkgs { inherit system; };

		extensions = with builtins; with pkgs; let
			generated = import ./generated/open-vsx/generated.nix {
				fetchurl = builtins.fetchurl;
				fetchgit = builtins.fetchGit;
				fetchFromGitHub = pkgs.fetchFromGitHub;
			};
			groupedByPublisher = (groupBy (e: e.publisher) (attrValues generated));
			pkgDefinition = e: with e; with vscode-utils; {
				inherit name;
				value = buildVscodeMarketplaceExtension {
					vsix = src;
					mktplcRef = {
						inherit version;
						publisher = marketplacePublisher;
						name = marketplaceName;
					};
					meta = with lib; {
						inherit changelog description downloadPage homepage;
						license = licenses.${license};
					};
				};
			};
		in mapAttrs (_: val: listToAttrs (map pkgDefinition val)) groupedByPublisher;
	in {
		devShell = pkgs.mkShell {
			shellHook = ''
    			export DENO_DIR="$(pwd)/.deno"
			'';
			nativeBuildInputs = with pkgs; [
				deno nvfetcher
			];
			buildInputs = [ ];
		};
		packages = extensions;
	});
}
