defmodule Servy.FourOhFourCounter do

  @name :four_oh_four_counter

  use GenServer

  # Client Interface

  def start_link(_arg) do
    IO.puts "Starting the 404 counter..."
    GenServer.start_link(__MODULE__, %{}, name: @name)
  end

  def bump_count(path) do
    GenServer.call @name, {:bump_count, path}
  end

  def get_counts do
    GenServer.call @name, :get_counts
  end

  def get_count(path) do
    GenServer.call @name, {:get_count, path}
  end

  def reset do
    GenServer.cast @name, :reset
  end

  # Server Callbacks

  def handle_cast(:reset, _state) do
    {:noreply, %{}}
  end

  def handle_call({:get_count, _from, path}, state) do
    count = Map.get(state, path, 0)
    {:reply, count, state}
  end

  def handle_call(:get_counts, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:bump_count, path}, _from, state) do
    new_state = Map.update(state, path, 1, fn existing_value -> existing_value + 1 end)
    {:reply, :ok, new_state}
  end
end
