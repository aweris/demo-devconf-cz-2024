# Demo - Rethinking CI/CD: A Leap Beyond Bash and YAML

This repository contains the code for the demo presented in the talk "Rethinking CI/CD: A Leap Beyond Bash and YAML" at [DevConf.CZ 2024](https://www.devconf.info/cz/).

## Quick Start

Just run the following command to build and run the demo:

```bash
make run
```

Open your browser and navigate to [http://localhost:8080](http://localhost:8080) to see the demo in action.

## Development

### Make Targets

```text
usage: make [target] ...

targets :

build    Builds demo binary
run      Runs demo binary
lint     Runs golangci-lint analysis
test     Runs go test
clean    Cleanup everything
help     Shows this help message
```

## Credits

This demo inspired by [this talk](https://github.com/sagikazarmark/demo-kcd-romania-2024) presented by [Márk Sági-Kazár](https://github.com/sagikazarmark) at [KCD Romania 2024](https://community.cncf.io/events/details/cncf-kcd-romania-presents-kcd-romania-2024/).