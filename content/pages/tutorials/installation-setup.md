---
layout: tutorial
title: Chapter 2 &ndash; Modern Ruby Installation Guide
permalink: /tutorials/installation-setup/
difficulty: beginner
summary: Greet the world, explore Ruby objects, and learn how the console responds to your code.
next_tutorial:
  title: Chapter 3 My First Ruby Program
  url: /tutorials/first-ruby-program/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: Ruby resources
    url: /pages/resources/
---

### Why Use a Version Manager? {#why-version-manager}

Forget old manual compilation methods. Using a version manager is the standard practice in the Ruby community because it allows you to:

- Switch between Ruby versions easily - work on different projects with different Ruby requirements
- No permission issues - install Ruby and gems without sudo
- Isolate project dependencies - keep your development environment clean
- Easy updates - simple commands to install new Ruby versions

#### Quick Start: rbenv (Recommended) {#rbenv-installation}

rbenv is lightweight and unobtrusive - perfect for most developers.

<p><p>

#### 1. Install rbenv & Dependencies {#rbenv-dependencies}

macOS:
- `brew install rbenv openssl readline`
Ubuntu/Debian:

  ```bash
  sudo apt update && sudo apt install -y git build-essential libssl-dev libreadline-dev zlib1g-dev
  git clone https://github.com/rbenv/rbenv.git ~/.rbenv
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(rbenv init -)"' >> ~/.bashrc
  exec $SHELL
  ```


#### 2. Install ruby-build plugin {#ruby-build}

```bash
`git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build`
```

#### 3. Install & Use Ruby {#install-ruby}

```bash
`rbenv install 3.3.0`
`rbenv global 3.3.0`
`ruby -v  # Verify installation`
```

### Alternative: RVM {#rvm-installation}

RVM is a full-featured alternative with more built-in functionality.

One-line install:
<p></p>

```bash
`\curl -sSL https://get.rvm.io | bash -s stable`
`source ~/.rvm/scripts/rvm`
`rvm install 3.3.0`
`rvm use 3.3.0 --default`
```

#### Verify & Use {#verify-installation}

Test your installation with these commands:
<p></p>

```bash
`ruby -v    # Should show ruby 3.3.0+`
`gem -v     # Check gem manager`
`gem install rails  # Test gem installation`
```

#### Which Should You Choose? {#which-to-choose}
- Choose rbenv if you prefer simplicity and a lightweight tool that stays out of your way
- Choose RVM if you want more built-in features and don't mind a more complex setup

#### Troubleshooting {#troubleshooting}

Common issues:
<p></p>
- "Command not found" after installation: Run exec $SHELL or restart your terminal
- Ruby compilation fails: Ensure you've installed all required dependencies
- Gem permission errors: Never use sudo with gem install - use a version manager instead
