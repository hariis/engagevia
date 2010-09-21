# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def get_post_participation_comment_count(contact)
    user = User.find_by_id(contact.id)
    user_posts = Engagement.find_all_by_user_id(user.id)
    user_comments = user.comments
    return "(#{user_comments.size} comments from #{user_posts.size} posts)"
  end
  
    
  def title_tag_line
    "EngageVia, Engage in Conversations & Collaborate with your friends Privately"
  end
  def tag_line
    "Engage in Conversations & Collaborate with your friends Privately"
  end
  def in_place_editor(field_id, options = {})
    function =  "new Ajax.InPlaceEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    js_options = {}

    if protect_against_forgery?
      options[:with] ||= "Form.serialize(form)"
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')"
    end

    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options] if options[:options]
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    mode = %(#{options[:mode]}) if options[:mode]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?
    if options[:mode]
      function << ",#{mode})"
    else
      function << ")"
    end

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place editing capabilities.
  def in_place_editor_field(object, method, tag_options = {}, in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    # LM: Note addition of the controller option
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :controller => object.to_s.pluralize, :action => "set_#{object}_#{method}", :id => tag.object.id })
    tag.to_content_tag(tag_options.delete(:tag), tag_options) +
    in_place_editor(tag_options[:id], in_place_editor_options)
  end


  #CHANGE: The following two methods were added to allow in place editing with a select field instead of a text field.
  #         For more info visit: http://www.thetacom.info/2008/03/21/rails-in-place-editing-plugin-w-selection/
  # Scriptaculous Usage: new Ajax.InPlaceCollectionEditor( element, url, { collection: [array], [moreOptions] } );
  def in_place_collection_editor(field_id, options = {})
    function =  "new Ajax.InPlaceCollectionEditor("
    function << "'#{field_id}', "
    function << "'#{url_for(options[:url])}'"

    #CHANGED: Added to allow plugin to work with Rails 2 session forgery protection
    if protect_against_forgery?
      options[:with] ||= "Form.serialize(form)"
      options[:with] += " + '&authenticity_token=' + encodeURIComponent('#{form_authenticity_token}')"
    end
    #end CHANGE

    js_options = {}
    js_options['collection'] = %(#{options[:collection]})
    js_options['cancelText'] = %('#{options[:cancel_text]}') if options[:cancel_text]
    js_options['okText'] = %('#{options[:save_text]}') if options[:save_text]
    js_options['loadingText'] = %('#{options[:loading_text]}') if options[:loading_text]
    js_options['savingText'] = %('#{options[:saving_text]}') if options[:saving_text]
    js_options['rows'] = options[:rows] if options[:rows]
    js_options['cols'] = options[:cols] if options[:cols]
    js_options['size'] = options[:size] if options[:size]
    js_options['externalControl'] = "'#{options[:external_control]}'" if options[:external_control]
    js_options['loadTextURL'] = "'#{url_for(options[:load_text_url])}'" if options[:load_text_url]
    js_options['ajaxOptions'] = options[:options] if options[:options]
    #CHANGED: To bring in line with current scriptaculous usage
    js_options['htmlResponse'] = !options[:script] if options[:script]
    js_options['callback']   = "function(form) { return #{options[:with]} }" if options[:with]
    js_options['clickToEditText'] = %('#{options[:click_to_edit_text]}') if options[:click_to_edit_text]
    js_options['textBetweenControls'] = %('#{options[:text_between_controls]}') if options[:text_between_controls]
    js_options['value'] = %('#{options[:value]}') if options[:value]
    function << (', ' + options_for_javascript(js_options)) unless js_options.empty?

    function << ')'

    javascript_tag(function)
  end

  # Renders the value of the specified object and method with in-place select capabilities.
  def in_place_editor_select_field(object, method, tag_options = {}, in_place_editor_options = {})
    object_instance = self.instance_variable_get("@#{object.to_s}")
    field_id = "#{object}_#{method}_#{object_instance.id}_in_place_editor"
    #tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    #tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    #span_content = tag.to_content_tag(tag_options.delete(:tag), tag_options)
    alt_text = in_place_editor_options[:alt_text] || object_instance.send(method.to_s)
    span_content = "<span id=\"#{field_id}\" class=\"in_place_editor_field\">#{alt_text}</span>" if alt_text

    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :action => "set_#{object}_#{method}", :id => object_instance.id })
    in_place_editor_options[:value] = object_instance.send(method).id
    js_content = in_place_collection_editor(field_id, in_place_editor_options)
    span_content + js_content
  end

  def in_place_rich_editor(field_id, options = {})
    js =  in_place_editor(field_id, options)
    js.sub!("Ajax.InPlaceEditor", "Ajax.InPlaceRichEditor")
  end


  # Renders the value of the specified object and method with in-place editing capabilities.
  def in_place_rich_editor_field(object, method, tag_options = {}, in_place_editor_options = {})
    tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
    tag_options = {:tag => "span", :id => "#{object}_#{method}_#{tag.object.id}_in_place_editor", :class => "in_place_editor_field"}.merge!(tag_options)
    # LM: Note addition of the controller option
    in_place_editor_options[:url] = in_place_editor_options[:url] || url_for({ :controller => object.to_s.pluralize, :action => "set_#{object}_#{method}", :id => tag.object.id })
    tag.to_content_tag(tag_options.delete(:tag), tag_options) +
    in_place_rich_editor(tag_options[:id], in_place_editor_options)
  end
  require 'rexml/parsers/pullparser'

   def truncate_html(input, len = 30, extension = "...")
        def attrs_to_s(attrs)
          return '' if attrs.empty?
          attrs.to_a.map { |attr| %{#{attr[0]}="#{attr[1]}"} }.join(' ')
        end

        p = REXML::Parsers::PullParser.new(input)
          tags = []
          new_len = len
          results = ''
          while p.has_next? && new_len > 0
            p_e = p.pull
            case p_e.event_type
          when :start_element
            tags.push p_e[0]
            results << "<#{tags.last} #{attrs_to_s(p_e[1])}>"
          when :end_element
            results << "</#{tags.pop}>"
          when :text
            results << p_e[0].first(new_len)
            new_len -= p_e[0].length
          else
            results << "<!-- #{p_e.inspect} -->"
          end
        end

        tags.reverse.each do |tag|
          results << "</#{tag}>"
        end

        results.to_s + (input.length > len ? extension : '')
      end

end
