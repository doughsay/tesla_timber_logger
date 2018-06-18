defmodule TeslaTimberLogger.MixProject do
  use Mix.Project

  def project do
    [
      app: :tesla_timber_logger,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Tesla middleware for logging outgoing requests to Timber.io.
    """
  end

  defp package do
    [
      maintainers: ["Chris Dosé <chris.dose@gmail.com>"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/doughsay/tesla_timber_logger"
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.9", only: :test},
      {:tesla, "~> 1.0"},
      {:timber, "~> 2.8"}
    ]
  end
end
