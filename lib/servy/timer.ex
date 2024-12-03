defmodule Servy.Timer do
  def remind(reminder, seconds) do
    spawn(
      fn ->
        :timer.sleep(seconds * 1000)
        IO.puts(reminder)
      end)
  end
end

# Servy.Timer.remind("Stand Up", 5)
# Servy.Timer.remind("Sit Down", 10)
# Servy.Timer.remind("Fight, Fight, Fight", 15)

# :timer.sleep(:infinity)
