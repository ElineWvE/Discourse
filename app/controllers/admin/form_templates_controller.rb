# frozen_string_literal: true

class Admin::FormTemplatesController < Admin::StaffController
  before_action :ensure_form_templates_enabled

  def index
    form_templates = FormTemplate.all
    render_serialized(form_templates, FormTemplateSerializer, root: "form_templates")
  end

  def new
  end

  def create
    params.require(:name)
    params.require(:template)
    # TODO: ensure template param is a valid JSON?

    template = FormTemplate.new(name: params[:name], template: params[:template])

    if template.save
      render_serialized(template, FormTemplateSerializer, root: "form_template")
    else
      render_json_error(template)
    end
  end

  def show
    template = FormTemplate.find(params[:id])
    render_serialized(template, FormTemplateSerializer, root: "form_template")
  end

  def edit
    FormTemplate.find(params[:id])
  end

  def update
    template = FormTemplate.find(params[:id])

    if template.update(name: params[:name], template: params[:template])
      render_serialized(template, FormTemplateSerializer, root: "form_template")
    else
      render_json_error(template)
    end
  end

  def destroy
    template = FormTemplate.find(params[:id])
    template.destroy

    render json: success_json
  end

  private

  def ensure_form_templates_enabled
    raise Discourse::InvalidAccess.new unless SiteSetting.experimental_form_templates
  end
end
