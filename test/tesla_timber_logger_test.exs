defmodule TeslaTimberLoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Tesla.Env

  defmodule Client do
    use Tesla

    plug Tesla.Middleware.TimberLogger

    adapter fn env ->
      env = Tesla.put_header(env, "content-type", "text/plain")

      case env.url do
        "/connection-error" ->
          {:error, :econnrefused}

        "/server-error" ->
          {:ok, %{env | status: 500, body: "error"}}

        "/client-error" ->
          {:ok, %{env | status: 404, body: "error"}}

        "/redirect" ->
          {:ok, %{env | status: 301, body: "moved"}}

        "/ok" ->
          {:ok, %{env | status: 200, body: "ok"}}
      end
    end
  end

  describe "TimberLogger" do
    test "connection error" do
      log = capture_log(fn -> Client.get("/connection-error") end)

      assert log =~ "[info]  Sent GET /connection-error"
      assert log =~ "[error] :econnrefused"
    end

    test "server error" do
      log = capture_log(fn -> Client.get("/server-error") end)

      assert log =~ "[info]  Sent GET /server-error"
      assert log =~ "[error] Received 500 response"
    end

    test "client error" do
      log = capture_log(fn -> Client.get("/client-error") end)

      assert log =~ "[info]  Sent GET /client-error"
      assert log =~ "[error] Received 404 response"
    end

    test "redirect" do
      log = capture_log(fn -> Client.get("/redirect") end)

      assert log =~ "[info]  Sent GET /redirect"
      assert log =~ "[warn]  Received 301 response"
    end

    test "ok" do
      log = capture_log(fn -> Client.get("/ok") end)

      assert log =~ "[info]  Sent GET /ok"
      assert log =~ "[info]  Received 200 response"
    end
  end

  describe "TimberLogger with log_level function" do
    defmodule ClientWithLogLevelFun do
      use Tesla

      plug Tesla.Middleware.TimberLogger, log_level: &log_level/1

      defp log_level(env) do
        if env.status >= 400 && env.status < 500, do: :warn, else: :default
      end

      adapter fn env ->
        case env.url do
          "/server-error" ->
            {:ok, %{env | status: 500, body: "server error"}}

          "/not-found" ->
            {:ok, %{env | status: 404, body: "not found"}}

          "/ok" ->
            {:ok, %{env | status: 200, body: "ok"}}
        end
      end
    end

    test "not found" do
      log = capture_log(fn -> ClientWithLogLevelFun.get("/not-found") end)

      assert log =~ "[info]  Sent GET /not-found"
      assert log =~ "[warn]  Received 404 response"
    end

    test "server error" do
      log = capture_log(fn -> ClientWithLogLevelFun.get("/server-error") end)

      assert log =~ "[info]  Sent GET /server-error"
      assert log =~ "[error] Received 500 response"
    end

    test "ok" do
      log = capture_log(fn -> ClientWithLogLevelFun.get("/ok") end)

      assert log =~ "[info]  Sent GET /ok"
      assert log =~ "[info]  Received 200 response"
    end
  end

  describe "TimberLogger with static log_level" do
    defmodule ClientWithStaticLogLevel do
      use Tesla

      plug Tesla.Middleware.TimberLogger, log_level: :info

      adapter fn env ->
        case env.url do
          "/server-error" ->
            {:ok, %{env | status: 500, body: "server error"}}

          "/not-found" ->
            {:ok, %{env | status: 404, body: "not found"}}

          "/ok" ->
            {:ok, %{env | status: 200, body: "ok"}}
        end
      end
    end

    test "not found" do
      log = capture_log(fn -> ClientWithStaticLogLevel.get("/not-found") end)

      assert log =~ "[info]  Sent GET /not-found"
      assert log =~ "[info]  Received 404 response"
    end

    test "server error" do
      log = capture_log(fn -> ClientWithStaticLogLevel.get("/server-error") end)

      assert log =~ "[info]  Sent GET /server-error"
      assert log =~ "[info]  Received 500 response"
    end

    test "ok" do
      log = capture_log(fn -> ClientWithStaticLogLevel.get("/ok") end)

      assert log =~ "[info]  Sent GET /ok"
      assert log =~ "[info]  Received 200 response"
    end
  end

  describe "TimberLogger with service_name" do
    defmodule ClientWithServiceName do
      use Tesla

      plug Tesla.Middleware.TimberLogger, service_name: "my-service"

      adapter fn env ->
        case env.url do
          "/ok" ->
            {:ok, %{env | status: 200, body: "ok"}}
        end
      end
    end

    test "ok" do
      log = capture_log(fn -> ClientWithServiceName.get("/ok") end)

      assert log =~ "[info]  Sent GET /ok to my-service"
      assert log =~ "[info]  Received 200 response from my-service"
    end
  end
end
