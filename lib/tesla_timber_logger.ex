defmodule Tesla.Middleware.TimberLogger do
  @moduledoc """
  Tesla middleware for logging outgoing requests to Timber.io.

  Using this middleware will log all requests and responses using Timber.io formatting and metadata.

  ### Example usage
  ```
  defmodule MyClient do
    use Tesla
    plug Tesla.Middleware.TimberLogger, service_name: "my-service"
  end
  ```

  ### Options

  - `:service_name` - the name of the external service (optional)
  - `:log_level` - custom function for calculating log level (see below)

  ### Custom log levels

  By default, the following log levels will be used:
  - `:error` - for errors, 5xx and 4xx responses
  - `:warn` - for 3xx responses
  - `:info` - for 2xx responses

  You can customize this setting by providing your own `log_level/1` function:
  ```
  defmodule MyClient do
    use Tesla
    plug Tesla.Middleware.TimberLogger, log_level: &my_log_level/1

    def my_log_level(env) do
      case env.status do
        404 -> :info
        _ -> :default
      end
    end
  end
  ```
  """

  require Logger
  alias Tesla.Env
  alias Timber.Events.{HTTPRequestEvent, HTTPResponseEvent}

  @behaviour Tesla.Middleware

  @impl true
  def call(env, next, opts) do
    Logger.info(fn -> log_request(env, opts) end)
    timer = Timber.start_timer()

    response = Tesla.run(env, next)

    level = log_level(response, opts)
    Logger.log(level, fn -> log_response(response, timer, opts) end)

    response
  end

  defp log_level({:error, _}, _), do: :error

  defp log_level({:ok, env}, opts) do
    case Keyword.get(opts, :log_level) do
      nil ->
        default_log_level(env)

      fun when is_function(fun) ->
        case fun.(env) do
          :default -> default_log_level(env)
          level -> level
        end

      atom when is_atom(atom) ->
        atom
    end
  end

  defp default_log_level(env) do
    cond do
      env.status >= 400 -> :error
      env.status >= 300 -> :warn
      true -> :info
    end
  end

  defp log_request(env, opts) do
    event =
      HTTPRequestEvent.new(
        direction: "outgoing",
        url: serialize_url(env),
        method: env.method,
        headers: env.headers,
        body: env.body,
        request_id: Logger.metadata()[:request_id],
        service_name: opts[:service_name]
      )

    {HTTPRequestEvent.message(event), event: event}
  end

  defp log_response({:error, reason}, _, _), do: Logger.error(fn -> inspect(reason) end)

  defp log_response({:ok, env}, timer, opts) do
    time_ms = Timber.duration_ms(timer)

    event =
      HTTPResponseEvent.new(
        direction: "incoming",
        status: env.status,
        time_ms: time_ms,
        headers: env.headers,
        body: normalize_body(env),
        request_id: Logger.metadata()[:request_id],
        service_name: opts[:service_name]
      )

    {HTTPResponseEvent.message(event), event: event}
  end

  defp serialize_url(%Env{url: url, query: query}), do: Tesla.build_url(url, query)

  defp normalize_body(env) do
    case Tesla.get_header(env, "content-encoding") do
      "gzip" ->
        "[gzipped]"

      "deflate" ->
        "[zipped]"

      _ ->
        env.body
    end
  end
end
