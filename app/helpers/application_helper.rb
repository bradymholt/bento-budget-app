module ApplicationHelper
	def controller_nav_link(text, link)
	    nav_link(text, link, false)
	end

	def action_nav_link(text, link)
		nav_link(text, link, true)
	end

	def nav_link(text, link, include_action)
		recognized = Rails.application.routes.recognize_path(link)
	    if recognized[:controller] == params[:controller] && (!include_action || recognized[:action] == params[:action])
	        content_tag(:li, :class => "active #{recognized[:controller]}_#{recognized[:action]}") do
	            link_to(text, link)
	        end
	    else
	        content_tag(:li, :class => "#{recognized[:controller]}_#{recognized[:action]}") do
	            link_to(text, link)
	        end
	    end
	end

	def flash_class(level)
	    case level
	        when :notice then "alert alert-info"
	        when :success then "alert alert-success"
	        when :error then "alert alert-error"
	        when :alert then "alert alert-error"
	    end
	end
end
