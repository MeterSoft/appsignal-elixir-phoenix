defmodule Appsignal.Phoenix.EventHandlerTest do
  use ExUnit.Case
  alias Appsignal.{Phoenix, Span, Test}

  setup do
    Test.Span.start_link()
    Test.Tracer.start_link()

    :ok
  end

  test "is attached to the router_dispatch event" do
    assert attached?([:phoenix, :router_dispatch, :start])
  end

  describe "after receiving a router_dispatch-start event" do
    setup [:create_root_span, :router_dispatch_start_event]

    test "keeps the handler attached" do
      assert attached?([:phoenix, :router_dispatch, :start])
    end

    test "sets the transaction's action name" do
      assert [{%Span{}, "AppsignalPhoenixExampleWeb.PageController#index"}] =
               Test.Span.get!(:set_name)
    end
  end

  describe "after receiving a router_dispatch-start event with non-atom opts" do
    setup [:create_root_span]

    setup do: do_router_dispatch_start_event(atom?: false)

    test "keeps the handler attached" do
      assert attached?([:phoenix, :router_dispatch, :start])
    end

    test "does not set the transaction's action name" do
      assert Test.Span.get(:set_name) == :error
    end
  end

  describe "after receiving an endpoint-start event" do
    setup [:create_root_span, :endpoint_start_event]

    test "starts a child span", %{span: parent} do
      assert [{"web", ^parent}] = Test.Tracer.get!(:create_span)
    end

    test "sets the span's name" do
      assert [{%Span{}, "call.phoenix_endpoint"}] = Test.Span.get!(:set_name)
    end
  end

  describe "after receiving an endpoint-start and an endpoint-stop event" do
    setup [:create_root_span, :endpoint_start_event, :endpoint_finish_event]

    test "finishes an event" do
      assert [{%Span{}}] = Test.Tracer.get!(:close_span)
    end
  end

  defp attached?(event) do
    event
    |> :telemetry.list_handlers()
    |> Enum.any?(fn %{id: id} ->
      id == {Phoenix.EventHandler, event}
    end)
  end

  defp create_root_span(_context) do
    [span: Appsignal.Tracer.create_span("root")]
  end

  defp router_dispatch_start_event(_context) do
    do_router_dispatch_start_event()
  end

  defp do_router_dispatch_start_event(plug_opts \\ :index) do
    :telemetry.execute(
      [:phoenix, :router_dispatch, :start],
      %{time: -576_460_736_044_040_000},
      %{
        conn: %Plug.Conn{},
        log: :debug,
        path_params: %{},
        pipe_through: [:browser],
        plug: AppsignalPhoenixExampleWeb.PageController,
        plug_opts: plug_opts,
        route: "/"
      }
    )
  end

  def endpoint_start_event(_context) do
    :telemetry.execute(
      [:phoenix, :endpoint, :start],
      %{time: -576_460_736_044_040_000},
      %{
        conn: %Plug.Conn{},
        options: []
      }
    )
  end

  def endpoint_finish_event(_context) do
    :telemetry.execute(
      [:phoenix, :endpoint, :stop],
      %{duration: 49_474_000},
      %{
        conn: %Plug.Conn{status: 200},
        options: []
      }
    )
  end
end