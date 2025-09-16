module NavigationHelper
  # Usage: nav_link_to "Label", path, icon: "file.svg"
  def nav_link_to(label, path, icon: nil)
    active = current_page?(path)
    classes = [
      "flex items-center gap-3 px-3 py-2 rounded-lg transition",
      active ? "bg-white/15 text-white" : "text-white/80 hover:bg-white/10 hover:text-white"
    ].join(" ")

    icon_tag = icon.present? ? image_tag(icon, class: "h-4 w-4 opacity-80") : ""

    link_to path, class: classes do
      safe_join([icon_tag, content_tag(:span, label)], " ")
    end
  end
end