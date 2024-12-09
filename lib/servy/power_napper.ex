defmodule Servy.PowerNapper do
  def power_nap() do

    parent = self()

    spawn(fn -> send(parent, {:slept, other_power_nap()}) end)

    receive do
      {:slept, time} -> IO.puts "Slept #{time} ms"
    end

  end

  defp other_power_nap() do
    time = :rand.uniform(10_000)
    :timer.sleep(time)
    time
  end
end
