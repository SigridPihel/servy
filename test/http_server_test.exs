defmodule HttpServerTest do
  use ExUnit.Case

  alias Servy.HttpServer
  alias Servy.HttpClient

  test "accepts a request on a socket and sends back a response" do

    spawn(HttpServer, :start, [4013])

    {:ok, response} = HTTPoison.get "http://localhost:4013/wildthings"
    assert response.status_code == 200
    assert response.body == "Bears, Lions, Tigers"
  end

  defp remove_whitespace(text) do
    String.replace(text, ~r{\s}, "")
  end

end
