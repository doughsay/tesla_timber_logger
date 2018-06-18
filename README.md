# Tesla Timber Logger Middleware

[![Build Status](https://travis-ci.com/doughsay/tesla_timber_logger.svg?branch=master)](https://travis-ci.com/doughsay/tesla_timber_logger)
[![Code Coverage](https://img.shields.io/codecov/c/github/doughsay/tesla_timber_logger.svg)](https://codecov.io/gh/doughsay/tesla_timber_logger)
[![Hex.pm](https://img.shields.io/hexpm/v/tesla_timber_logger.svg)](http://hex.pm/packages/tesla_timber_logger)

Tesla middleware for logging outgoing requests to Timber.io.

Using this middleware will log all requests and responses using Timber.io formatting and metadata.

## Installation

Add `tesla_timber_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tesla_timber_logger, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
defmodule MyClient do
  use Tesla
  plug Tesla.Middleware.TimberLogger
end
```

## Configuration

You can pass in an optional `service_name` to this middleware to tag all
outgoing http requests with the given name. This will be searchable in
Timber.io's dashboard.

```elixir
plug Tesla.Middleware.TimberLogger, service_name: "my-service"
```

The docs can
be found at [https://hexdocs.pm/tesla_timber_logger](https://hexdocs.pm/tesla_timber_logger).
