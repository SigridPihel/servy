defmodule Servy.Wildthings do
  alias Servy.Bear

  @pages_path Path.expand("../../db", __DIR__)

  def list_bears do

    @pages_path
    |> Path.join("bears.json")
    |> read_json
    |> Poison.decode!(as: %{"bears" => [%Bear{}]})
    |> Map.get("bears")

  end

  def read_json(file) do
    case File.read(file) do
      {:ok, body} ->
        body
      {:error, reason} -> IO.inspect "Error reading #{file}: #{reason}"
      "[]"
    end
  end

  def get_bear(id) when is_integer(id) do
    Enum.find(list_bears(), fn(b) -> b.id == id end)
  end

  def get_bear(id) when is_binary(id) do
    id |> String.to_integer |> get_bear
  end

end
