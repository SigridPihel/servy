defmodule Servy.Handler do

  @moduledoc "Handles HTTP requests."

  alias Servy.Conv
  alias Servy.BearController

  @pages_path Path.expand("../../pages", __DIR__)

  import Servy.Plugins, only: [rewrite_path: 1, log: 1, track: 1]
  import Servy.Parser, only: [parse: 1]

  @doc "Transforms the request into a response."
  def handle(request) do
    request
    |> parse
    |> rewrite_path
    |> log
    |> route
    |> track
    |> format_response
  end

  def route(conv) do
    route(conv, conv.method, conv.path)
  end

  def route(conv, "DELETE", "/bears/" <> _id) do
    BearController.delete(conv, conv.params)
  end

  def route(conv, "GET", "/wildthings") do
    %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
  end

  def route(conv, "GET", "/bears") do
    BearController.index(conv)
  end

  def route(conv, "GET", "/bears/" <> id) do
    params = Map.put(conv.params, "id", id)
    BearController.show(conv, params)
  end

  def route(conv, "POST", "/bears") do
    BearController.create(conv, conv.params)
  end

  def route(conv, "GET", "/about") do
      @pages_path
      |> Path.join("about.html")
      |> File.read
      |> handle_file(conv)
  end

  def route(conv, method: _method, path: path) do
    %{ conv | status: 404, resp_body: "No #{path} here!"}
  end

  def handle_file({:ok, content}, conv) do
    %{ conv | status: 200, resp_body: content }
  end

  def handle_file({:error, :enoent}, conv) do
    %{ conv | status: 404, resp_body: "File not found!" }
  end

  def handle_file({:error, reason}, conv) do
    %{ conv | status: 500, resp_body: "File error: #{reason}" }
  end

  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    Content-Type: text/html\r
    Content-Length: #{String.length(conv.resp_body)}\r
    \r
    #{conv.resp_body}
    """
  end

end
