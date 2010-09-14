class ContactsController < ApplicationController
 
  layout "application"
  
  #-----------------------------------------------------------------------------------------------------
  def migrate_existing_contacts
      Group.delete_all
      Membership.delete_all
      
      @posts = Post.find(:all)
      @posts.each do |post|
        
        engagements = Engagement.find(:all, :conditions => ["post_id = ?", post.id])
        if engagements.size > 1
          engagements.each do |engagement|
            if engagement.user_id != engagement.invited_by
                invitee = User.find_by_id(engagement.user_id)
                inviter = User.find_by_id(engagement.invited_by)
                inviter.add_to_address_book(invitee)                
            end
          end
        end
        
        if post.comments.count > 0
            comments = post.comments.find(:all)
            unless comments.nil?
              comments.each do |comment|
                if comment.owner != post.owner
                  comment.owner.add_to_address_book(post.owner)
                end
              end
            end
        end        
     end
     #redirect_to :controller => 'contacts', :action => 'index'
     redirect_to contacts_path
  end

  # GET /contacts
  # GET /contacts.xml
  def index
    @contacts = current_user.get_address_book_contacts
     
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @contacts }
    #end
  end

  # GET /contacts/1
  # GET /contacts/1.xml
  def show
    @contact = Contact.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @contact }
    end
  end

  # GET /contacts/new
  # GET /contacts/new.xml
  def new
    @contact = Contact.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contact }
    end
  end

  # GET /contacts/1/edit
  def edit
    @contact = Contact.find(params[:id])
  end

  # POST /contacts
  # POST /contacts.xml
  def create
    @contact = Contact.new(params[:contact])

    respond_to do |format|
      if @contact.save
        flash[:notice] = 'Contact was successfully created.'
        format.html { redirect_to(@contact) }
        format.xml  { render :xml => @contact, :status => :created, :location => @contact }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contacts/1
  # PUT /contacts/1.xml
  def update
    @contact = Contact.find(params[:id])

    respond_to do |format|
      if @contact.update_attributes(params[:contact])
        flash[:notice] = 'Contact was successfully updated.'
        format.html { redirect_to(@contact) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contact.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1
  # DELETE /contacts/1.xml
  def destroy
    @contact = Contact.find(params[:id])
    @contact.destroy

    respond_to do |format|
      format.html { redirect_to(contacts_url) }
      format.xml  { head :ok }
    end
  end
end
