defmodule Servy.Handler do

  @moduledoc "Handles HTTP requests."

  alias Servy.Conv
  alias Servy.BearController
  alias Servy.Api.BearController, as: ApiBearController

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
    |> put_content_length
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

  def route(conv, "GET", "/api/bears") do
    Servy.Api.BearController.index(conv)
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

  def route(conv, "POST", "/api/bears") do
    ApiBearController.create(conv, conv.params)
  end

  def route(conv, "GET", "/pages" <> name) do
    @pages_path
      |> Path.join("#{name}")
      |> File.read
      |> handle_file(conv)
      |> markdown_to_html
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

  def markdown_to_html(%Conv{status: 200} = conv) do
    %{ conv | resp_body: Earmark.as_html!(conv.resp_body) }
  end

  def markdown_to_html(%Conv{} = conv), do: conv

  def put_content_length(conv) do
    headers = Map.put(conv.resp_headers, "Content-Length", String.length(conv.resp_body))
    %{conv | resp_headers: headers}
  end

  def format_response_headers(conv) do
    for {header_key, header_value} <- conv.resp_headers["Content-Length"] do
      "#{header_key}: #{header_value}\r"
    end |> Enum.sort |> Enum.reverse |> Enum.join("\n")
  end


  def format_response(%Conv{} = conv) do
    """
    HTTP/1.1 #{Conv.full_status(conv)}\r
    #{format_response_headers(conv)}
    \r
    #{conv.resp_body}
    """
  end

end
