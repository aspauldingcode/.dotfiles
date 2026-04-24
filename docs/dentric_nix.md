Skip to main content
What is dendritic Nix and how does it work? : r/NixOS

Open menu
 

r/NixOS


Open chat
Create
Create post
Open inbox

User Avatar
Expand user menu
 
Back
 
Go to NixOS
r/NixOS
•
4mo ago
PaceMakerParadox

What is dendritic Nix and how does it work?

Like what makes it different than flakes+home manager, I don't get it, is it just the same with boilerplate reduction? Cause that is what I am getting, I am probably missing something but that is really why I am asking.

I also think is somehow includes the same syntax/modules that would work on any system dynamically, which like 1. How and 2. Wouldn' that not be declarative at that point?.

What are the points/benefits for gaming?

I rnad the GitHub and did not really get much beyond that.
 
Upvote
29

Downvote
 
33
Go to comments


Share
 u/NordicSemiconductor avatar
NordicSemiconductor
•
Promoted
 
Nordic nRF54L Series, the next-level wireless SoCs
 Thumbnail image: Nordic nRF54L Series, the next-level wireless SoCs
 
Sort by:

Best
 
Search Comments
Expand comment search
Comments Section
Fereydoon37
•
4mo ago
I skimmed through the tutorial and linked materials from the post yesterday. It seems like it's a new buzz word for creating reusable Nix code by focusing on the "feature" you want to achieve.

For NixOS, as a desktop operating system, that could mean setting up your coding environment, which could import a subfeature for an editor like vim, or whatever is needed to use say Python. Another example would be a feature for gaming, with subfeatures for specific games like OpenMorrowind, or vendors like steam.

The materials make a big point of not redefining these things for every computer that needs a feature, and not spreading things out over disconnected files for NixOS/nixpkgs, Home Manager, Darwin, etc. Apparently that's how a lot of people have been doing things.

Instead you define the thing in one place, grouping all configuration for nixpkgs, home manager etc. together, and then include / activate that bundle for computers / users that need it.

The tutorial uses flake-parts to accommodate this structure. It also mentions that you don't need to use flake-parts to write "dendritic" nix. The advantage of adopting flake-parts and their file organisation, is standardisation; people can exchange code, and the files become self-documenting to people familiar with the conventions.

Personally I'm not sure that using flake-parts like this is superior to an ad-hoc file structure convention, and using the existing nixpkgs / home-manager module systems to define options, that computers / users opt into.

The impression I had of how features can't be imported twice, and how to deal with things need to be activated / imported conditionally, makes me suspect it's a bit of a leaky abstraction, but I haven't given it it's fair shake either, so take that with a grain of salt. Basically, what I'm trying to say is that ostensibly the existing nixpkgs module system has better conflict handling / resolution.

nixgang
•
4mo ago
This is where I'm at as well. It's true that reconciling HM/NixOS/disko/devshell/etc-modules for multiple machines requires some care to keep it DRY and maintainable, but putting an abstraction on top of them all doesn't seem right to me.

I haven't studied enough to know for sure though, maybe it's good for some use cases, but probably not for me.

Reddich07
•
4mo ago
The only “abstraction” you introduce is that each module, previously residing in its own file, now gets a name within a top-level module. You can still separate each top-level module into multiple files, each containing your previous modules, if you prefer. The only difference would be two lines bracketing your module. You don’t make any other changes to your code. So, migration is quite straightforward. Of course, you do make structural changes when applying the Dendritic Pattern, but that’s independent of flake-parts.

Initially, I was skeptical about using a new library that appears so frequently in every code fragment (What if I want to revert? What if development stops in the future?). However, the benefits are so significant that it became a no-brainer after I understood the concept. Spoiler alert: It’s like switching to flakes. You start questioning why this isn’t part of the core system and why it’s not the standard way to do it. I wonder if you’ll feel the same way.

nixgang
•
4mo ago
Yes I know how flake-parts work and use it where it fits, what I'm questioning is the dendritic pattern, not flake-parts
More replies
u/ghostnation66 avatar
ghostnation66
•
1mo ago
Do you know where I can learn more about basic nix?

u/mightyiam avatar
mightyiam
•
1mo ago
Profile Badge for the Achievement Top 1% Commenter Top 1% Commenter
https://nix.dev https://zero-to-nix.com/ https://nixcademy.com/posts/
u/Ashtefere avatar
Ashtefere
•
4mo ago
Def seems like buzzwording.

I have a script that generates my flake file from a template and then it rebuilds and switches.

The template generator also loops over a directory of single file flakes that include all the inputs for each flake as well, so i dont to write all the inputs for all my configs in one file - they are purely isolated.

That way I can add/remove files to a folder to add/remove features to me config - makes it a lot easier to import flakes for things too.
u/Buttars0070 avatar
Buttars0070
•
4mo ago
I'm definitely starting to feel friction with the traditional approach separating files across different configuration types. I'm regularly finding myself asking "where does that functionality live?" and once I figure out what type of configuration it is "is it a core feature or a system specific feature..." It's a mess. I'm going to experiment getting rid of separating my core from my feature and eventually move to something like you described.
u/Silly-Name-999 avatar
Silly-Name-999
•
2mo ago
and not spreading things out over disconnected files for NixOS/nixpkgs, Home Manager, Darwin, etc. Apparently that's how a lot of people have been doing things.
...
Personally I'm not sure that using flake-parts like this is superior to an ad-hoc file structure convention, and using the existing nixpkgs / home-manager module systems to define options, that computers / users opt into.
How would you go about creating a single file that contains NixOS and nix-darwin configuration? Is your repo public?
u/Epistechne avatar
Epistechne
•
4mo ago
Still just starting to learn it myself so I will probably get some things wrong, but it is a pattern for how to write modules so that your configuration is more easily scaled to complex multisystem multi user configs while keeping maintenance low.

Following this design pattern the flake file becomes a simple list of inputs without the complex outputs section I've seen in many configs.

Modules don't require maintaining a bunch of relative paths for imports ../../../ , the structure makes it that you can often move files and directories without having to update paths.

The modules you write are more easily composed together from smaller modules with less glue code and options.

Modules have the code for different system classes (nixos, darwin, homemanager) in one file instead of scattered in separate files.
u/mightyiam avatar
mightyiam
•
4mo ago
Profile Badge for the Achievement Top 1% Commenter Top 1% Commenter
I love seeing how many have looked into the dendritic pattern. I want to do a Full Time Nix podcast episode about it with several users, in case anyone is interested.

u/ghostnation66 avatar
ghostnation66
•
1mo ago
Im interested
u/Vortriz avatar
Vortriz
•
4mo ago
•
Edited 4mo ago
simplest example: lets say you want to configure a program/feature that requires setup in both home-manager and nixos options. but since the HM part has to be imported into HM, you would create a separate file for it. this gets messy when you have separate out things like that.

using dendritic pattern, you configure it in one file (or place) itself by thinking of it as a "feature" that you want to achieve. even if that feature might require you to mess with HM, nixos modules, hell even devshell, you should be able to define it nicely in one place. flake module from flake-parts allows you to achieve this.

i use a dendritic pattern based framework (called unify) in my dots.

example files:

https://github.com/Vortriz/dotfiles/blob/main/modules/programs/terminal/shell.nix
https://github.com/Vortriz/dotfiles/blob/main/modules/toplevel/nix.nix
no_brains101
•
4mo ago
•
Edited 4mo ago
Profile Badge for the Achievement Top 1% Commenter Top 1% Commenter
Kept hearing this term and was also curious, so I looked it up. TIL my config is like, almost but maybe not quite dendritic. pre-dendritic I guess, cause its been around for longer than that term. I have stuff grouped by feature and they export modules of both types from each feature when needed. However I did not extend that idea to my system configs using flake-parts modules, which does seem somewhat interesting. I just had a hub of features and imported/enabled the ones i needed in each system config

It seems to be a new design pattern which aims to help people to figure out how to group their config by feature in a way that allows them to affect both home manager and nixos from 1 file (along with whatever else), rather than 2 separate files containing modules with a lot of duplicated code for each, plus a file exporting that other stuff.

Commonly people do this pattern these days with flake parts modules that import both the nixos and home manager module associated with that feature, and because its flake-parts it can also do stuff like, output packages from the main flake as well if you had a wrapped package, or import them directly into the configurations exported by your flake

Before that, people like myself who made their config before this term existed made files which were a function which you call with { inherit inputs; home-manager = true or false; } which returned a nixos or home manager module, and then called that in a hub to get both modules into a hub variable, and then called that hub from their flake and passed the hub to their home manager and nixos configs. Those main configs can then import whatever they want from that, and your flake can grab whatever from that hub too and export it. This allows you to not have to worry about the actual paths to those things, and keep stuff as easily shared between configs for home manager and nixos as possible, while also being able to export them from the top level flake

If you give those modules an enable option you can auto-import them in every config and just enable them wherever, or you can just decide if you want to import them or not per config if they don't have an enable option. You can also stuff whatever you want into said hub, not just modules.

Dendritic patten is basically just that, but with flake parts so that you dont have to deal with a hub variable you pass around and its slightly easier to share info between bundles. The parts can do those things directly, so you no longer have to pass the hub and import it there, you just do it right there in the flake-part module and then its imported in all the configs, just like if you had a hub, and imported all the modules it exported automatically. Or, I guess you could also have them export from the main flake there, and then use inputs.self as your hub.

It seems there is a lot of ways to follow this pattern, but the key is to group stuff by feature, and then have each feature bundle be able to export nixos modules, home manager modules, packages etc. which may or may not be then automatically imported in your config for a particular machine or home manager.

It seems kinda like a reasonable pattern, it is something you can partially apply too if you only want to go partially dendritic. IDK. I might drift more this way eventually, using flake-parts to manage my hub thing instead of passing it around might be useful. I already use flake parts for mapping my nixos and home manager configs to legacyPackages.<system>.nixos/homeConfigurations.<name> so, whats the harm in using it for a bit more I guess.

I think I like the idea where I use dendritic flake-parts modules for the things I had in my hub, and have them export themselves from the flake, and then in my nixos and home manager configs for the systems, I can grab them from inputs.self

That way my hub thing can be better managed and organized using flake-parts, and otherwise I can keep the overall hub and import thing I have going on which I kinda like for the system/home configs. But who knows, lets see what I do I guess. That will at least be how I start, and then maybe I will extend it to my main configs which use that stuff and maybe I wont.

IDK Im doing a lot of stuff right now. Ill get to it eventually lol. I was tending towards this, but I think this pattern can teach me something I can use to make it cleaner and more enjoyable and simple to use once I get it set up. On the bright side, my new nix-wrapper-modules repo fits into it kinda nicely, as they export packages, but can also export modules if you add one in an option, and one could make a nice little flake parts module to grab various outputs and do stuff with them.

no_brains101
•
4mo ago
Profile Badge for the Achievement Top 1% Commenter Top 1% Commenter
TL;DR

flake-parts is the module system, applied to flake outputs.

in your outputs function, you just call the flake-parts eval module function, and then you import modules / set module options which set up flake outputs rather than setting up the outputs directly. This lets you create options on top.

Dendritic pattern is a pattern in which those flake modules are organized by feature, and output all the things, home-manager/nixos modules, packages, overlays, devShells, whatever, from the same file/directory.

They can either take those things and export them directly from the main flake, or they can import them directly in the home manager and nixos configs exported by the flake, or both, different people do that differently.

You can emulate this pattern without flake-parts, but flake-parts really makes it into a more organized thing rather than just having a hub and nix expressions which output a mix of stuff.
kesor
•
4mo ago
There are multiple aspects to it, the one I like most is using modules in such a way that the same file can be seen by both NixOS and Home Manager.

Example:

{
  flake.modules.nixos.system-secrets-sops =
    { pkgs, inputs, ... }:
    {
      imports = [ inputs.sops-nix.nixosModules.sops ];

      environment.systemPackages = with pkgs; [
        sops
        gnupg
      ];

      sops = {
        defaultSopsFormat = "yaml";
        defaultSopsFile = ../../../../secrets/nixos.yaml;

        gnupg = {
          home = "/var/lib/sops/gnupg";
          sshKeyPaths = [ ];
        };

        age = {
          keyFile = null;
          sshKeyPaths = [ ];
        };
      };
    };

  flake.modules.homeManager.sops =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      options.sops.enable = lib.mkEnableOption "sops-nix secrets management";

      config = lib.mkMerge [
        {
          sops = {
            defaultSopsFormat = "yaml";
            defaultSopsFile = ../../../../secrets/home-manager.yaml;
            gnupg = {
              home = config.programs.gpg.homedir;
              sshKeyPaths = [ ];
            };
          };
        }
        (lib.mkIf config.sops.enable {
          home.packages = with pkgs; [
            sops
            gnupg
          ];
        })
      ];
    };
}
Then when I import inputs.self.modules.homeManager.sops in my Home Manager, or I import inputs.self.modules.nixos.sops in my NixOS modules, I get the code from that one single file. Make organizing related things/aspects close together in single files much more convenient. In my case inputs is a specialArgs in NixOS and extraSpecialArgs in Home Manager, and its the flake's inputs.

So I guess the magic is inputs.self, for the flake to be able to reference itself. And some magic with import-tree that finds all my modules by scanning a folder.

Example relevant piece of a flake.nix:

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { config, ... }:
      let
        inherit (inputs.nixpkgs-unstable) lib;

        treeModules = inputs.import-tree.initFilter (
          p: lib.hasSuffix "/default.nix" p && !lib.hasInfix "/_" p
        );
        treeMachines = inputs.import-tree.initFilter (
          p: lib.hasSuffix "/configuration.nix" p && !lib.hasInfix "/_" p
        );
        treeHomes = inputs.import-tree.initFilter (p: lib.hasSuffix ".nix" p && !lib.hasInfix "/_" p);
      in
      {
        imports = [
          inputs.flake-parts.flakeModules.modules
          (treeModules ./modules)
          (treeMachines ./machines)
          (treeHomes ./homes)
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake = {
          nixosConfigurations = lib.mapAttrs (
            _: cfg: inputs.nixos-stable.lib.nixosSystem cfg
          ) config.flake.machineConfigs;

          homeConfigurations = lib.mapAttrs (
            _: cfg: inputs.home-manager.lib.homeManagerConfiguration cfg
          ) config.flake.homeConfigs;
        };

BizNameTaken
•
4mo ago
You do not need to configure hm stuff in another file. You can write hm config in a nixos module with home-manager.users.<user> = { ... };, or to make it even simpler, use lib.mkAliasOptionModule

kesor
•
4mo ago
I don't want to nixos-rebuild each time I want to change something in home manager ... that is why I have home manager for.
u/Autodesk avatar
u/Autodesk
•
Promoted
 
No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine.
 No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine. 
 No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine. 
 No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine. 
 No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine. 
 No waitlist. No lab schedule. Go from footage to editable CG. Create export-ready assets you can refine in tools like Maya, Blender, and Unreal Engine. 
autodesk.com
Sign Up
Reddich07
•
4mo ago
You might have missed my post about the (guide) I wrote. It should address all your questions. Here are the short answers: 1. No, it’s not a “boilerplate reduction.” 2. It has nothing to do with switching from “declarative” to “dynamically.” in any way. 3. It benefits gaming setups by making complex setups more manageable.

If you only have one machine running Nix and are only interested in optimizing your setup, such as for gaming, the Dendritic Pattern won’t make much of a difference. You can usually handle this low-level complexity with any file/code structure (more or less elegant).

The Dendritic Pattern is particularly useful when you want to use your code on multiple hosts and different configuration contexts, such as Home-Manager or Nix-Darwin. It organizes your code in a way that makes it easier to create, change, update, and fix bugs, which was previously a dependency nightmare. This is perhaps the main advantage. Unfortunately, it requires more than a short forum answer to fully understand. It‘s not a new „buzzword“ for things that people already did with their current configurations. I was told that the pattern was „discovered“ by people who used flake-parts and used „top-level“-modules which have 1. access to the flake outputs, 2. have the possibility to share values/code between different contexts (NixOS, Home-Manager, …). This sounds complicated at first, it isn‘t if you have seen some examples. The idea behind the Dendritic Pattern is so powerful, that it was redefined in a generic way (previously it was linked to flake-parts, but you can even do it without, but you may need some kind of tool/library). The most commonly used tool for the Dendritic Pattern is flake-parts. This is no coincidence, it fits perfectly.

If you have a complex setup and want to refactor your code because you’ve reached a limit with your current structure, I can assure you that delving into the Dendritic Pattern is worth it. Once you understand the basics, it’s quite easy to work with.

Feel free to ask if you don’t understand something in the guide. (Please use the linked guide thread for this, so that others can benefit from the answers there as well.)
u/zardvark avatar
zardvark
•
4mo ago
I don't think that there are any benefits to gaming, whatsoever. The primary benefit is simplifying the task of managing multiple machines.

That said, I am far from expert. I have been reading about flake-parts and the dendritic pattern on and off for the past few weeks and while configuring the modules seems straightforward enough, I'm not so sure that I understand the glue that holds everything together. I've been looking at user configurations on the github, but since I'm not a developer, much of the configurations are a bit opaque to me. I like to understand the code, rather than copy / paste it and hope for the best, eh? And, I'm simply not there yet.

BTW - Vimjoyer released an all too brief vid on flake-parts recently, for those interested.

Anywho, I have multiple machines to manage, so I am quite interested in this topic, but thus far figuring this out has been slow going.

u/Epistechne avatar
Epistechne
•
4mo ago
Did you see this post yet, I find it really helpful https://old.reddit.com/r/NixOS/comments/1pxqm2w/github_docstevedendriticdesignwithflakeparts_a/

u/zardvark avatar
zardvark
•
4mo ago
No, I had not seen that one.

Thanks so much!!!
u/zardvark avatar
zardvark
•
4mo ago
Thanks again!

I've only just scratched the surface, but this resource has already answered a few of my questions.

Cheers!!!

u/Epistechne avatar
Epistechne
•
4mo ago
No problem, I'm a nix noob and I think I would have struggled for months without this guide. It's really timely that he made it just as I'm starting to try learning it.
silver_blue_phoenix
•
4mo ago
I think i ended up building this by myself, as a natural evolution of using this system config flake when I started out.

Don't know what flake parts is; don't think I need to use a new tool for doing what I'm doing by hand.

My nixos config basically has the following structure;

All nixos things are kept in a nixos folder.
Inside this folder, there is a default.nix that makes it so that every module in the subdirectory modules get's a option myNixOS.<module-name>.enable that when set to true, imports the said module.
Hosts directory has a default.nix that sets up modules shared across all hosts, and sets up my personal user
Each host lies in it's own subdirectory with an entry point <hostname>/default.nix that configures the system, and enables whichever module it wants to.
I have a library function that generates a nixos config automatically from all the different folders in nixos/hosts
I have nix-darwin setup that doesn't play nice with this but I managed to integrate. I also have a raspberry-pi nix setup that also doesn't play super nice (I don't want the default.nix to be imported for example; it's just a wireguard server that doesn't need my user.) home-manager follows a similar layout.

u/Epistechne avatar
Epistechne
•
4mo ago
Misterio77 repo is a nice structure but it is not dendritic, it's what dendritic is an alternative to.

I'd read this article that shows which side of the config matrix these are on https://not-a-number.io/2025/refactoring-my-infrastructure-as-code-configurations/#flipping-the-configuration-matrix
Reddich07
•
4mo ago
„flake-parts provides the options that represent standard flake attributes and establishes a way of working with system (from the web page). Sounds very abstract, I know. For a comprehensive introduction, watch this video from @vimjoyer. Flake-parts is not a configuration setup; it’s a fundamental and incredibly powerful concept: how to work with flakes within your code.

To clarify, your setup neither recreates the way to work with flakes (like flake-parts) nor utilizes the design pattern introduced with the Dendritic Pattern.

Don’t misunderstand me: You have a highly sophisticated and effective setup that meets your requirements. That’s perfectly fine—no need to change it. Nix is a programming language, and you can accomplish anything without relying on specific tools or design patterns. Perhaps at some point in the future, you’ll encounter increased complexity that necessitates restructuring your setup. In such cases, consider exploring the Dendritic Pattern to see if it can assist you and if it’s worth the effort.
Fereydoon37
•
4mo ago
What you're doing differently from the dendritic pattern, from the eyes of an outsider, is that you're not separating concerns as advocated. Instead of making a module for Web browsing, and another for gaming etc., your code is driven by hosts / users.

For example, a quick skim reveals that you're setting up Firefox and steam for a specific user in one file. Instead you could opt into gaming and Web browsing 'features' for that user. That carries the advantage that if you add a Mac system, and you want to use a different Web browser like Safari there, or also want to provide say lutris globally to gaming set ups, you don't need to change anything to your system or user configuration; your 'business logic' if you will. You only need to touch the 'implementation' of the functionality (feature) you're affecting. Conversely if there's a problem with a feature, you immediately know where to look first.

The separation of concerns and the divide between implementation and business / core logic, while good form, are nothing new. u/nixgang and I both seem to have implemented the core ideas already in mostly standard Nix, because frankly it's what emerges naturally from complex requirements.

At one point I managed six hosts with 4 users that each had to do a distinct but overlapping subset of server duties, programming, low latency music and audio production, creative writing, and gaming amongst other things. Not abstracting over that is not tenable.

I'm skeptic about the pattern as a rigid implementation thereof, and I'm afraid it might get in the way of abstracting even further. I do however see value in standardisation, and making it easy to follow for people without a formal background in informatics.
u/ThomasLeonHighbaugh avatar
ThomasLeonHighbaugh
•
20d ago
The use of the word "dendratic", calling to mind the brain and playing to the common superiority complexes had around here, this is hardcore buzzwording that is really just yet another module writing pattern that may work well for some, personally I am prone to compartmentalization in my life and in my Linux so its less appealing to me but that's fine.

Write modules how you want to, please stop inventing new esoteric labels for the same things. Especially just to up sell a module writing tactic. Can we just make it a little less esoteric nonsense?
Community Info Section
r/NixOS
 Joined
NixOS - Purely functional
Created Aug 26, 2011
Public
48K
Weekly visitors
1.1K
Weekly contributions
COMMUNITY ACHIEVEMENTS
Repeat Contributor
Flag Planter
Repeat Contributor, 
Flag Planter
2 unlocked

View All
MODERATORS
Message Mods
 u/kxra avatar
u/kxra
u/iElectric avatar
u/iElectric
Domen
View all moderators
PROMOTED
 
 sidebar promoted post thumbnail
Reddit Rules
Privacy Policy
User Agreement
Your Privacy Choices
Accessibility
Reddit, Inc. © 2026. All rights reserved.
