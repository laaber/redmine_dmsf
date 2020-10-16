# encoding: utf-8
# frozen_string_literal: true
#
# Redmine plugin for Document Management System "Features"
#
# Copyright © 2012    Daniel Munn <dan.munn@munnster.co.uk>
# Copyright © 2011-20 Karel Pičman <karel.picman@kontron.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../../test_helper', __FILE__)

class DmsfWebdavMkcolTest < RedmineDmsf::Test::IntegrationTest

  fixtures :dmsf_folders

  def test_mkcol_requires_authentication
    process :mkcol, '/dmsf/webdav/test1'
    assert_response :unauthorized
  end

  def test_mkcol_fails_to_create_folder_at_root_level
    process :mkcol, '/dmsf/webdav/test1', params: nil, headers: @admin
    assert_response :method_not_allowed
  end

  def test_should_not_succeed_on_a_non_existant_project
    process :mkcol, '/dmsf/webdav/project_doesnt_exist/test1', params: nil, headers: @admin
    assert_response :not_found
  end

  def test_should_not_succed_on_a_non_dmsf_enabled_project
    @project1.disable_module! :dmsf
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", params: nil, headers: @jsmith
    assert_response :not_found
  end

  def test_should_not_create_folder_without_permissions
    @role.remove_permission! :folder_manipulation
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/folder", params: nil, headers: @jsmith
    assert_response :forbidden
  end

  def test_should_fail_to_create_folder_that_already_exists
    process :mkcol,
      "/dmsf/webdav/#{@project1.identifier}/#{@folder6.title}", params: nil, headers: @jsmith
    assert_response :method_not_allowed
  end

  def test_should_create_folder_for_non_admin_user_with_rights
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test1", params: nil, headers: @jsmith
    assert_response :success
    Setting.plugin_redmine_dmsf['dmsf_webdav_use_project_names'] = true
    project1_uri = ERB::Util.url_encode(RedmineDmsf::Webdav::ProjectResource.create_project_name(@project1))
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/test2", params: nil, headers: @jsmith
    assert_response :not_found
    process :mkcol, "/dmsf/webdav/#{project1_uri}/test3", params: nil, headers: @jsmith
    assert_response :success # Created
  end

  def test_create_folder_in_subproject
    process :mkcol, "/dmsf/webdav/#{@project1.identifier}/#{@project3.identifier}/test1", params: nil,
            headers: @admin
    assert_response :success
  end

end