# Technology Detection Patterns

Patterns for detecting and quantifying the technology stack of a repository.

## Dependency File Mappings

Presence of these files indicates the corresponding technology:

### Python
| File | Indicates |
|------|-----------|
| `requirements.txt` | pip dependencies |
| `pyproject.toml` | Modern Python project (pip, poetry, or other) |
| `setup.py` | Legacy Python package |
| `Pipfile` | Pipenv project |
| `environment.yml` | Conda environment |
| `conda.yaml` | Conda environment |
| `setup.cfg` | Python package config |

**Detection logic:**
- `environment.yml` or `conda.yaml` → Use conda/mamba base image
- Otherwise → Use standard Python image with pip/uv

### JavaScript/Node.js
| File | Indicates |
|------|-----------|
| `package.json` | Node.js project |
| `package-lock.json` | npm lockfile |
| `yarn.lock` | Yarn project |
| `pnpm-lock.yaml` | pnpm project |
| `bun.lockb` | Bun project |

**Detection logic:**
- Check `package.json` for `type: "module"` (ESM vs CommonJS)
- Check for `scripts.start` to determine run command
- Check `engines` field for Node version requirements

### Go
| File | Indicates |
|------|-----------|
| `go.mod` | Go modules project |
| `go.sum` | Go dependencies locked |
| `Gopkg.toml` | Legacy dep project |

**Detection logic:**
- Check `go.mod` for Go version
- Look for `main.go` or `cmd/` directory for entry points

### Rust
| File | Indicates |
|------|-----------|
| `Cargo.toml` | Rust project |
| `Cargo.lock` | Rust dependencies locked |

**Detection logic:**
- Check `Cargo.toml` for binary vs library (`[[bin]]` section)
- Look for `src/main.rs` (binary) vs `src/lib.rs` (library)

### Ruby
| File | Indicates |
|------|-----------|
| `Gemfile` | Ruby/Bundler project |
| `Gemfile.lock` | Ruby dependencies locked |
| `.ruby-version` | Ruby version specification |

**Detection logic:**
- Check for Rails (`config/application.rb`, `Rakefile` with Rails)
- Check for Sinatra or other frameworks in Gemfile

### Java
| File | Indicates |
|------|-----------|
| `pom.xml` | Maven project |
| `build.gradle` | Gradle project |
| `build.gradle.kts` | Gradle Kotlin DSL |
| `.mvn/` | Maven wrapper |
| `gradlew` | Gradle wrapper |

**Detection logic:**
- Maven → Use `maven:3-eclipse-temurin-*` image
- Gradle → Use `gradle:jdk*` image
- Check for Spring Boot in dependencies

### PHP
| File | Indicates |
|------|-----------|
| `composer.json` | Composer project |
| `composer.lock` | PHP dependencies locked |
| `artisan` | Laravel project |

**Detection logic:**
- Laravel → Consider `php-fpm` with nginx or Apache
- Plain PHP → CLI or built-in server

### Other Languages
| File | Language |
|------|----------|
| `Makefile` | C/C++ (often) |
| `CMakeLists.txt` | C/C++ (CMake) |
| `mix.exs` | Elixir |
| `rebar.config` | Erlang |
| `Package.swift` | Swift |
| `pubspec.yaml` | Dart/Flutter |
| `*.csproj` | C#/.NET |
| `*.fsproj` | F#/.NET |

## File Extension Analysis

Count files by extension to estimate language distribution:

| Extension | Language |
|-----------|----------|
| `.py` | Python |
| `.js`, `.mjs`, `.cjs` | JavaScript |
| `.ts`, `.tsx` | TypeScript |
| `.jsx` | React/JavaScript |
| `.go` | Go |
| `.rs` | Rust |
| `.rb` | Ruby |
| `.java` | Java |
| `.kt`, `.kts` | Kotlin |
| `.php` | PHP |
| `.c`, `.h` | C |
| `.cpp`, `.cc`, `.hpp` | C++ |
| `.cs` | C# |
| `.swift` | Swift |
| `.ex`, `.exs` | Elixir |
| `.sh`, `.bash` | Shell |

### Calculating Confidence

1. Count files by extension (excluding `node_modules`, `.git`, `vendor`, etc.)
2. Calculate percentage for each language
3. Cap individual confidence at 75% to allow for mixed stacks
4. Primary technology = highest confidence

Example:
```
Repository has:
- 45 .py files
- 12 .js files  
- 3 .html files

Total relevant: 57 files
Python: 45/57 = 79% → capped at 75%
JavaScript: 12/57 = 21%
→ Primary: Python (75%), Secondary: JavaScript (21%)
```

## Common Patterns by Tech Stack

### Python Data Science
**Indicators:**
- `requirements.txt` with numpy, pandas, scipy, scikit-learn
- Jupyter notebooks (`.ipynb` files)
- `environment.yml` with conda dependencies

**Base image:** `continuumio/miniconda3` or `mambaorg/micromamba`

### Python Web Service
**Indicators:**
- `requirements.txt` with flask, django, fastapi, uvicorn
- `app.py`, `main.py`, `wsgi.py`, `asgi.py`
- `manage.py` (Django)

**Base image:** `python:3.x-slim`
**CMD:** uvicorn, gunicorn, or framework-specific

### Node.js Web Service
**Indicators:**
- `package.json` with express, fastify, koa, next
- `server.js`, `index.js`, `app.js`

**Base image:** `node:lts-slim`
**CMD:** `node server.js` or `npm start`

### Node.js Frontend Build
**Indicators:**
- `package.json` with react, vue, angular, vite, webpack
- `src/` with `.jsx`, `.tsx`, `.vue` files

**Base image:** `node:lts-slim` for build, then nginx for serving
**Note:** Often needs multi-stage build

### Go CLI/Service
**Indicators:**
- `go.mod` present
- `main.go` or `cmd/` directory

**Base image:** `golang:1.x-alpine` for build
**Final image:** `scratch` or `alpine` (Go compiles statically)

### Rust CLI/Service
**Indicators:**
- `Cargo.toml` with `[[bin]]`
- `src/main.rs`

**Base image:** `rust:1.x-slim` for build
**Final image:** `debian:bookworm-slim` (for dynamic linking) or `scratch` (static)

### Java/Spring Boot
**Indicators:**
- `pom.xml` or `build.gradle` with spring-boot
- `src/main/java/` structure
- `application.properties` or `application.yml`

**Base image:** `eclipse-temurin:21-jdk` for build, `eclipse-temurin:21-jre` for runtime
**Build:** `mvn package` or `gradle build`
**CMD:** `java -jar app.jar`

## README Analysis

Extract build/run instructions from README sections:

### Section Headers to Look For
- Installation
- Install
- Setup
- Getting Started
- Quick Start
- Building
- Build
- Usage
- Running
- Development

### Patterns to Extract
```markdown
## Installation
pip install -r requirements.txt    → pip dependencies
npm install                        → npm dependencies
go build                          → Go build command
cargo build --release             → Rust build command

## Running
python app.py                     → Python entry point
node server.js                    → Node entry point
./binary --flag                   → Binary with flags
```

### Environment Variables
Look for documented environment variables:
```markdown
Set the following environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `API_KEY`: Your API key
- `PORT`: Server port (default: 8000)
```

These should be documented in the Dockerfile or mentioned as runtime requirements.
