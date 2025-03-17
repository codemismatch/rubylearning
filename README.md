# Ruby Learning

A beautiful static website for learning Ruby programming language using the Typophic static site generator.

## Table of Contents

- [Introduction](#introduction)
- [Project Structure](#project-structure)
- [Core Commands](#core-commands)
- [Quick Start](#quick-start)
- [Project Configuration](#project-configuration)
- [Content Examples](#content-examples)
- [Deployment](#deployment)
  - [Deployment Options](#deployment-options)
  - [Deployment Process](#deployment-process)
  - [Path Fixing Process](#path-fixing-process)
  - [Custom Domain Setup](#custom-domain-setup)
  - [Troubleshooting Deployment](#troubleshooting-deployment)
- [Git Workflow](#git-workflow)
  - [Branch Structure](#branch-structure)
  - [Setting Up the Workflow](#setting-up-the-workflow)
  - [Development Workflow](#development-workflow)
- [Site Features](#site-features)
- [Ruby Learning Resources](#ruby-learning-resources)
- [Tutorials](#tutorials)
- [About](#about)
- [Troubleshooting](#troubleshooting)

## Introduction

Ruby Learning is a static website built to help beginners and intermediate developers learn the Ruby programming language through structured tutorials, examples, and practical exercises.

Ruby is designed for programmer happiness and productivity. Its elegant syntax is natural to read and easy to write.

```ruby
# This is Ruby code
def greet(name)
  puts "Hello, #{name}!"
end

greet("Ruby Learner")
```

## Project Structure

- `bin/` - Core utility scripts for building and managing the site
- `content/` - Source Markdown files for the site content
- `data/` - Data files for the site (for dynamic content)
- `public/` - Generated static site output
- `templates/` - HTML templates and assets (CSS, JS, images)
- `tools/` - Additional helper utilities

## Core Commands

The following commands are available for site management:

| Command | Description |
|---------|-------------|
| `bin/typophic` | Main static site generator |
| `bin/typophic-build` | Build the site with all optimizations |
| `bin/typophic-deploy` | Unified deployment system (local or GitHub Pages) |
| `bin/typophic-fix` | Fix common site issues |
| `bin/typophic-new` | Create new content |
| `bin/typophic-serve` | Local development server |

## Quick Start

### First-time Setup

```bash
# Make all scripts executable
chmod +x bin/*
```

### Building the Site

Build the site with all optimizations:

```bash
bin/typophic-build
```

### Preview the Site

Start a local development server:

```bash
bin/typophic-serve
```

Visit http://localhost:3000 in your browser.

### Creating New Content

Create a new post:

```bash
bin/typophic-new post "My New Ruby Tutorial"
```

Create a new page:

```bash
bin/typophic-new page "About Ruby"
```

## Project Configuration

The site configuration is stored in `config.yml` in the root directory. This file controls site-wide settings like:

```yaml
---
site_name: Ruby Learning
site_type: ruby
author: Typophic User
description: A beautiful static website for learning Ruby
url: http://example.com
permalink_style: pretty
date_format: "%B %-d, %Y"
markdown_extensions:
- tables
- fenced_code_blocks
- autolink
```

Additionally, you can configure repository settings in the config.yml file:

```yaml
# Git repository settings
repository:
  url: git@github.com:username/rubylearning.git
  branch: main
  deploy_branch: gh-pages
```

This allows you to specify:
- Your repository URL
- The main branch for source code (default: main)
- The branch for deployment (default: gh-pages)

## Content Examples

### Ruby Classes and Objects

Here's an example of Ruby classes and objects:

```ruby
class Book
  attr_accessor :title, :author, :pages
  
  def initialize(title, author, pages)
    @title = title
    @author = author
    @pages = pages
  end
  
  def to_s
    "#{@title} by #{@author} (#{@pages} pages)"
  end
  
  def read
    puts "You're reading #{@title}. Enjoy!"
  end
end

# Create new Book objects
book1 = Book.new("The Ruby Programming Language", "Matz", 472)
book2 = Book.new("Eloquent Ruby", "Russ Olsen", 448)

# Access attributes
puts book1.title   # => "The Ruby Programming Language"
puts book2.author  # => "Russ Olsen"

# Call methods
puts book1         # => "The Ruby Programming Language by Matz (472 pages)"
book2.read         # => "You're reading Eloquent Ruby. Enjoy!"
```

### Inheritance Example

```ruby
class Animal
  attr_accessor :name, :species
  
  def initialize(name, species)
    @name = name
    @species = species
  end
  
  def speak
    puts "#{@name} makes a sound"
  end
end

class Dog < Animal
  def initialize(name)
    super(name, "Canine")
  end
  
  def speak
    puts "#{@name} says: Woof!"
  end
end

class Cat < Animal
  def initialize(name)
    super(name, "Feline")
  end
  
  def speak
    puts "#{@name} says: Meow!"
  end
end

# Create some animals
dog = Dog.new("Rex")
cat = Cat.new("Whiskers")

# Call methods
dog.speak
cat.speak

puts "#{dog.name} is a #{dog.species}"
puts "#{cat.name} is a #{cat.species}"
```

## Deployment

### Deployment Options

The deployment system supports various options:

| Option | Description |
|--------|-------------|
| `--local` | Deploy for local development (starts a server) |
| `--remote URL` | Set the GitHub repository URL |
| `--force` | Force push to GitHub Pages |
| `--fix-only` | Only fix paths without building or deploying |
| `--build-only` | Only build site without deploying |
| `--custom-domain DOMAIN` | Set a custom domain |
| `--port PORT` | Port for local server (default: 3000) |
| `-h`, `--help` | Show help message |

### Basic Usage

#### Deploy to GitHub Pages

With configuration in config.yml:
```bash
bin/typophic-deploy
```

This will:
1. Read the repository URL from config.yml
2. Build the site
3. Fix paths for GitHub Pages
4. Deploy to the gh-pages branch

#### Deploy for Local Development

```bash
bin/typophic-deploy --local
```

This will:
1. Build the site
2. Fix paths for local development
3. Start a local server

### GitHub Pages

```bash
bin/typophic-deploy --remote git@github.com:username/rubylearning.git
```

### Custom Domain

```bash
bin/typophic-deploy --remote URL --custom-domain example.com
```

### Deployment Process

The deployment process handles several tasks automatically:

#### For Local Development

1. Builds the site
2. Fixes paths for local development
3. Starts a local server

#### For GitHub Pages

1. Builds the site 
2. Fixes paths for GitHub Pages
3. Creates necessary GitHub Pages files (.nojekyll, etc.)
4. Initializes Git repository if needed
5. Commits and pushes to gh-pages branch

### Path Fixing Process

The major challenge with multi-environment deployment is handling paths correctly:

#### Local Development Paths

- Paths are relative to the server root
- Example: `/css/style.css` → `http://localhost:3000/css/style.css`

#### GitHub Pages Paths

- Paths include the repository name
- Example: `/css/style.css` → `https://username.github.io/rubylearning/css/style.css`
- Base tag is added: `<base href="/rubylearning/">`

### Custom Domain Setup

If you prefer not to deal with subdirectories, you can use a custom domain:

1. Purchase a domain (e.g., rubylearning.com)
2. Deploy with `--custom-domain` option
3. Configure domain DNS settings to point to GitHub Pages

With a custom domain, your site will be served from the root, eliminating path issues.

### Troubleshooting Deployment

#### CSS/JS Not Loading

If styles or scripts are not loading:

1. Check browser console for 404 errors
2. Run path fixes: `bin/typophic-deploy --fix-only --local` or `--fix-only` for GitHub
3. Ensure template doesn't use hardcoded absolute paths

#### Links Not Working

If navigation links don't work:

1. Check that the base path is correctly set
2. Ensure links are properly relative or include base path
3. Run `bin/typophic-fix --links` to fix link issues

#### GitHub Pages Issues

If your GitHub Pages deployment isn't working:

1. Verify you're using the correct remote URL
2. Check that site is being pushed to gh-pages branch
3. In GitHub repository settings, ensure Pages is set to gh-pages branch

#### Missing Repository URL

If you get an error about missing repository URL:
1. Add it to config.yml:
   ```yaml
   repository:
     url: git@github.com:username/repo.git
   ```
2. Or specify it on the command line: 
   ```bash
   bin/typophic-deploy --remote git@github.com:username/repo.git
   ```

#### Failed to Push

If push fails:
1. Check your SSH key setup
2. Try a force push: `bin/typophic-deploy --force`
3. Verify the repository URL is correct

## Git Workflow

### Branch Structure

- **main** branch: Contains all source code, templates, and build scripts
- **gh-pages** branch: Contains only the built site (public directory)

### Setting Up the Workflow

If you haven't set up the workflow yet, run:

```bash
chmod +x setup-git-workflow-revised.sh
./setup-git-workflow-revised.sh
```

This script will:
1. Initialize a Git repository in the project root
2. Create a `.gitignore` file that excludes the `public` directory from the main branch
3. Commit all source code to the main branch
4. Verify that the typophic-deploy script exists

### Development Workflow

#### 1. Making Changes to the Site

Work directly on the main branch:

```bash
# Edit content, templates, or scripts
git add .
git commit -m "Your commit message"
```

#### 2. Building the Site Locally

To preview your changes:

```bash
bin/typophic-build
bin/typophic-serve
```

#### 3. Deploying to GitHub Pages

When you're ready to deploy, use your existing `typophic-deploy` script:

```bash
# Deploy built site to gh-pages branch
bin/typophic-deploy --remote https://github.com/USERNAME/REPO_NAME.git
```

#### 4. Publishing Source Code

Don't forget to also push your source code:

```bash
git push origin main
```

### Advanced Usage

#### Path Fixing Only

```bash
bin/typophic-deploy --fix-only --local
# or
bin/typophic-deploy --fix-only  # for GitHub
```

#### Building Only

```bash
bin/typophic-deploy --build-only
```

#### Forcing Push

```bash
bin/typophic-deploy --remote URL --force
```

### Best Practices

1. Use relative paths in templates when possible
2. Test locally before deploying to GitHub
3. Use `--fix-only` if you need to fix paths without rebuilding
4. Consider using a custom domain for production sites

## Site Features

- Syntax highlighting for Ruby code
- Responsive design for all devices
- Modern typography and layout
- Clean, distraction-free reading experience

## Ruby Learning Resources

Here's a curated collection of resources to help you on your Ruby learning journey.

### Official Documentation

- [Ruby Documentation](https://ruby-doc.org/) - The official documentation for the Ruby language
- [Ruby API](https://rubyapi.org/) - Modern and searchable Ruby API documentation
- [Ruby Style Guide](https://rubystyle.guide/) - A community-driven Ruby coding style guide

### Books

- **"The Ruby Programming Language"** by David Flanagan and Yukihiro Matsumoto
- **"Eloquent Ruby"** by Russ Olsen
- **"Practical Object-Oriented Design in Ruby"** by Sandi Metz
- **"Ruby Under a Microscope"** by Pat Shaughnessy
- **"Metaprogramming Ruby 2"** by Paolo Perrotta

### Online Courses and Tutorials

- [Ruby Koans](http://rubykoans.com/) - Learn Ruby through testing
- [The Odin Project](https://www.theodinproject.com/paths/full-stack-ruby-on-rails) - Free full-stack Ruby on Rails curriculum
- [Ruby Monk](https://rubymonk.com/) - Interactive Ruby tutorials
- [Codecademy Ruby Track](https://www.codecademy.com/learn/learn-ruby) - Interactive Ruby lessons
- [RubyGuides](https://www.rubyguides.com/) - Articles and tutorials on Ruby programming

### Community

- [Ruby Weekly](https://rubyweekly.com/) - A weekly newsletter about Ruby
- [Ruby on Rails Reddit](https://www.reddit.com/r/rails/) - A community for Rails developers
- [Ruby Reddit](https://www.reddit.com/r/ruby/) - A community for Ruby developers
- [Ruby Discord](https://discord.gg/ruby-lang) - Ruby community Discord server
- [Ruby on Rails Link](https://www.rubyonrails.link/) - Ruby on Rails community Slack

## Tutorials

Welcome to our curated list of Ruby tutorials. Here you'll find comprehensive guides to help you master Ruby programming.

### Latest Tutorials

- **Understanding Ruby Classes and Objects**
  Learn about object-oriented programming in Ruby through classes and objects. Discover how Ruby implements OOP concepts elegantly.

- **Ruby Code Examples**
  Practical code examples that demonstrate Ruby's capabilities and show real-world applications.

- **Welcome to Ruby Learning**
  A warm welcome to the Ruby Learning site with an introduction to what you can expect to learn.

### Coming Soon

* Ruby Blocks, Procs, and Lambdas
* Introduction to Ruby Metaprogramming
* Working with Ruby Collections
* Ruby Web Development Basics
* Testing in Ruby with RSpec
* Ruby Gems and Bundler

## About

This is a static website built with Typophic, a flexible static site generator designed for creating Ruby learning resources. The site aims to provide comprehensive tutorials, examples, and resources for learning Ruby programming language.

## Troubleshooting

If you encounter issues with your site, use the fix tool:

```bash
bin/typophic-fix --all
```

This will fix common issues like:
- Unprocessed template variables
- Path problems
- Link inconsistencies
- Tutorial page formatting
