defmodule ZaqWeb.Live.BO.EngineDispatch do
  @moduledoc """
  Shared Back Office helper for dispatching Engine role events.
  """

  alias Zaq.{Event, NodeRouter}

  def dispatch(action, request \\ %{}, opts \\ []) when is_list(opts) do
    Event.new(request, :engine, opts: Keyword.put(opts, :action, action))
    |> NodeRouter.dispatch()
    |> Map.get(:response)
  end

  def dispatch_confidential(action, request \\ %{}, opts \\ []) when is_list(opts) do
    dispatch(action, request, Keyword.put(opts, :confidential, true))
  end
end
