defmodule Surface.LiveComponent do
  @behaviour Surface.Translator.ComponentTranslator
  import Surface.Translator.ComponentTranslator

  alias Surface.Translator.{Directive, NodeTranslator}

  defmacro __using__(_) do
    quote do
      use Phoenix.LiveComponent
      use Surface.BaseComponent
      use Surface.EventValidator
      import Surface.Translator, only: [sigil_H: 2]

      import unquote(__MODULE__)
      @behaviour unquote(__MODULE__)

      def translator() do
        unquote(__MODULE__)
      end

      defoverridable translator: 0
    end
  end

  @callback begin_context(props :: map()) :: map()
  @callback end_context(props :: map()) :: map()
  @optional_callbacks begin_context: 1, end_context: 1

  def translate(mod, mod_str, attributes, directives, children, children_groups_contents, has_children?, caller) do

    rendered_props = Surface.Properties.render_props(attributes, mod, mod_str, caller)
    # TODO: Call put_default_props inside render_props? We could also have opts [as_keyword: true, put_default_props: true]
    # TODO: Add maybe_generate_id() or create a directive :id instead
    rendered_props = "Keyword.new(Surface.Properties.put_default_props(#{rendered_props}, #{inspect(mod)}))"

    [
      Directive.maybe_add_directives_begin(directives),
      maybe_add_begin_context(mod, mod_str, rendered_props),
      children_groups_contents,
      add_render_call("live_component", ["@socket", mod_str, rendered_props], has_children?),
      Directive.maybe_add_directives_after_begin(directives),
      maybe_add(NodeTranslator.translate(children, caller), has_children?),
      maybe_add("<% end %>", has_children?),
      maybe_add_end_context(mod, mod_str, rendered_props),
      Directive.maybe_add_directives_end(directives)
    ]
  end
end