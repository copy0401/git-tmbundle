class MiscController < ApplicationController
  layout "application", :only => [:init]
  def init
    puts "<h2>Initializing Git Repository in #{ENV['TM_PROJECT_DIRECTORY']}</h2>"
    puts htmlize(git.init(ENV["TM_PROJECT_DIRECTORY"]))
  end

  def external
    gui_type = git.config["git-tmbundle.ext-app"]
    case gui_type
    when "gitk"
      ext_gitk
    when "gitgui"
      ext_gitgui
    when "gitx"
      ext_gitx
    when "gitnub"
      ext_gitnub
    when "stree"
      ext_stree
    when "custom"
      ext_custom
    else
      puts "Select an external GUI tool from the config dialog(Bundles → Git → Config...)."
      output_show_tool_tip
    end
  end

  protected
    def first_which(*args)
      args.map do |arg|
        next if arg.blank?
        result = `which '#{arg}'`.strip
        return result unless result.empty?
      end
      nil
    end

    def run_detached(cmd, app_name)
      exit if fork            # Parent exits, child continues.
      Process.setsid          # Become session leader.
      exit if fork            # Zap session leader.

      # After this point you are in a daemon process
      pid = fork do
        STDOUT.reopen(open('/dev/null'))
        STDERR.reopen(open('/dev/null'))
        Thread.new do
          sleep 1.5
          %x{osascript -e 'tell app "#{app_name}" to activate'}
          exit
        end
        system(cmd)
      end

      Process.detach(pid)
      #inspired by http://andrejserafim.wordpress.com/2007/12/16/multiple-threads-and-processes-in-ruby/
    end

    def ext_gitk
      run_detached("cd '#{git.path()}'; PATH=#{File.dirname(git.git)}:$PATH && gitk --all", "Wish")
    end

    def ext_gitgui
      run_detached("cd '#{git.path()}'; PATH=#{File.dirname(git.git)}:$PATH && git gui", "Git Gui")
    end

    def ext_gitnub
      cmd = first_which(git.config["git-tmbundle.gitnub-path"], "nub", "/Applications/GitNub.app/Contents/MacOS/GitNub")
      if cmd
        run_detached(cmd + " #{ENV['TM_PROJECT_DIRECTORY']}", "Gitnub")
      else
        puts "Unable to find Gitnub.  Use the config dialog to set the Gitnub path to where you've installed it."
        output_show_tool_tip
      end
    end

    def ext_gitx
      cmd = first_which(git.config["git-tmbundle.gitx-path"], "gitx", "/Applications/GitX.app/Contents/Resources/gitx")
      if cmd
        run_detached("cd '#{ENV['TM_DIRECTORY']}';" + cmd, "GitX")
      else
        puts "Unable to find GitX.  Use the config dialog to set the GitX path to where you've installed it."
        output_show_tool_tip
      end
    end

    def ext_stree
      cmd = first_which(git.config["git-tmbundle.stree-path"], "stree", "/Applications/SourceTree.app/Contents/Resources/stree")
      if cmd
        run_detached("cd '#{git.path()}';" + cmd, "SourceTree")
      else
        puts "Unable to find SourceTree.  Use the config dialog to set the SourceTree path to where you've installed it."
        output_show_tool_tip
      end
    end

    def ext_custom
      cmd = git.config["git-tmbundle.ext-custom-cmd"]
      if cmd
        run_detached("cd '#{git.path()}'; " + cmd, "Custom Git GUI")
      else
        puts "Set the custom GUI command to use from the config dialog(Bundles → Git → Config...)."
        output_show_tool_tip
      end

    end
end