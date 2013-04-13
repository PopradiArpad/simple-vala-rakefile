#build rules for a simple vala project
#
#contact:popradi.arpad11@gmail.com
#
#doku
#https://live.gnome.org/Vala/Documentation/ParallelBuilds
#https://github.com/jimweirich/rake/blob/master/doc/rakefile.rdoc
#
#multitask doesnt work really, rake must be run as
#rake -m -j number_of_cores
#to parallelize the build
#
#Before use you must adapt the configurations of
#ProjectFileStructure and Build to your project file structure and build environment.




# The supported file structure is
# projectdir
#       production        #vala files for production code
#       test              #vala files for test code
#       generated         #intermediate files generated direct of indirect from both "production" and "test"
#       bin               #the executables for produciton and test
#
#Each vala file must have a different name in the "production" and in the test "directories".
#Because all generated files come to directory "generated" and there must be a one to one relationship
#between the vala files and theirs generated files.
#
#There is a vala file in both "production" and "test" that contains the main function.
#Becasue the main function is a must in each vala compilat that method name collides surely.
#Therefore it must be known which files are the main files for "production" and for "test".
class ProjectFileStructure

    def initialize()
        #create the generated directories
        FileUtils.mkdir_p(dir_of_generated_files)
        FileUtils.mkdir_p(dir_of_bin_files)
    end #initialize
    
    
    #project file structure parameters
    ##################################
    
    def dir_of_production_vala_files()
        "production"
    end #dir_of_production_vala_files
    
    def dir_of_test_vala_files()
        "test"
    end #dir_of_test_vala_files
    
    def dir_of_generated_files()
        "generated"
    end #dir_of_generated_files
    
    def dir_of_bin_files()
        "bin"
    end #dir_of_bin_files
    
    def production_executable()
        "#{dir_of_bin_files}/your_executable"
    end #production_executable
    
    def test_executable()
        "#{dir_of_bin_files}/your_test_executable"
    end #test_executable
    
    def main_vala_file_in_production_dir()
        "your_main.vala"
    end #main_vala_file_in_production_dir
    
    def main_vala_file_in_test_dir()
        "your_test_main.vala"
    end #main_vala_file_in_test_dir
    
    
    
    #maps between file types
    ########################
    
    def vala_file_of(file_name)
        case file_name
            when /\.vapi$/, /\.dep$/, /\.c$/ , /\.o$/  
                vala_file_in_production = file_name.pathmap("%{^#{dir_of_generated_files},#{dir_of_production_vala_files}}X.vala")
                vala_file_in_test       = file_name.pathmap("%{^#{dir_of_generated_files},#{dir_of_test_vala_files}}X.vala")
                File.exist?(vala_file_in_production) ? vala_file_in_production : vala_file_in_test
            when /\.vala$/
                file_name
            else
                throw "No map from #{file_name} to its vala file"
        end    
    end #vala_file_of
    
    def vapi_file_of(file_name)
        case file_name
            when /\.c$/, /\.dep$/   then file_name.pathmap("%X.vapi")
            when /\.vala$/          then file_name.pathmap("%{^#{dir_of_production_vala_files},#{dir_of_generated_files}}X.vapi").pathmap("%{^#{dir_of_test_vala_files},#{dir_of_generated_files}}X.vapi")
            else
                throw "No map from #{file_name} to its vapi file"
        end    
    end #vapi_file_of
    
    def c_file_of(file_name)
        case file_name
            when /\.o$/, /\.dep$/    then file_name.pathmap("%X.c")
            else
                throw "No map from file_name to its c file"
        end    
    end #c_file_of
    
    def dep_file_of(file_name)
        case file_name
            when /\.c$/,/\.o$/    then file_name.pathmap("%X.dep")
            else
                throw "No map from file_name to its dep file"
        end    
    end #dep_file_of

    def vapi_files_of(dep_file)
        if (File::exist?(dep_file))
            File::open(dep_file) do |f| 
                l = f.readlines[0]
                l.match(/(.*)\.dep:\s*(.*)$/)
                vapi_file_names = $~[2]
                return vapi_file_names.split
            end
        else
            main_vala_file_to_exclude = is_test_file(dep_file) ? main_vala_file_for_production : main_vala_file_for_test
            
            all_vapi_files.exclude(vapi_file_of(dep_file)).exclude(vapi_file_of(main_vala_file_to_exclude))
        end
    end #vapi_files_of

    def dir_of(file_name)
        File.dirname(file_name)
    end #dir_of
    
    
    
    #file collections
    #################
    
    def all_vala_files
        all_vala_files_for_production.include("#{dir_of_test_vala_files}/*.vala")
    end #all_vala_files
    
    def all_vala_files_for_production
        FileList["#{dir_of_production_vala_files}/*.vala"]
    end #all_vala_files_for_production
    
    def all_vala_files_for_test
        all_vala_files_for_production.exclude(main_vala_file_for_production).include("#{dir_of_test_vala_files}/*.vala")
    end #all_vala_files_for_test
    
    def all_vapi_files
        all_vala_files.ext('vapi').gsub("#{dir_of_production_vala_files}/","#{dir_of_generated_files}/").gsub("#{dir_of_test_vala_files}/","#{dir_of_generated_files}/")
    end #all_vapi_files
    
    def all_vapi_files_for_production
        all_vala_files_for_production.ext('vapi').gsub("#{dir_of_production_vala_files}/","#{dir_of_generated_files}/")
    end #all_vapi_files_for_production
    
    def all_vapi_files_for_test
        all_vala_files_for_test.ext('vapi').gsub("#{dir_of_production_vala_files}/","#{dir_of_generated_files}/").gsub("#{dir_of_test_vala_files}/","#{dir_of_generated_files}/")
    end #all_vapi_files_for_test
    
    def all_dep_files
        all_vapi_files.ext('dep')
    end #all_dep_files
    
    def all_c_files
        all_vapi_files.ext('c')
    end #all_c_files
    
    def all_o_files
        all_vapi_files.ext('o')
    end #all_o_files
    
    def all_o_files_for_production
        all_vapi_files_for_production.ext('o')
    end #all_o_files_for_production
    
    def all_o_files_for_test
        all_vapi_files_for_test.ext('o')
    end #all_o_files_for_test
    
    def all_generated_dirs()
        [dir_of_generated_files, dir_of_bin_files]
    end #all_generated_dirs
    
    private
    
    def is_test_file(file_name)
        (vala_file_of(file_name) =~ Regexp.new("#{dir_of_test_vala_files}/.*\.vala$")) ? true : false
    end #is_test_file
    
    def main_vala_file_for_production()
        "#{dir_of_production_vala_files}/#{main_vala_file_in_production_dir}"
    end #main_vala_file_for_production
    
    def main_vala_file_for_test()
        "#{dir_of_test_vala_files}/#{main_vala_file_in_test_dir}"
    end #main_vala_file_for_test
    
end #ProjectFileStructure

class Build

    include FileUtils #for method sh of rake
    
    def initialize(filestructur)
        @pfs = filestructur
    end #initialize
    
    private
    
    # A space-separated list of packages required by your
    # project. Names must be compatible with pkg-config, E.g.
    #    gobject-2.0 gtk+-3.0 clutter-1.0 gee-1.0 clutter-gtk-1.0
    PKGS		= ""

    # The path to the pkgconfig data. E.g.
    #   /home/user/installed/lib/pkgconfig
    PKGCONFIGPATH = ""

    # The vala compiler.
    VALAC		= "/usr/bin/valac"

    # Add any additional flags to pass to the vala compiler. E.g.
    #   --vapidir=vala_install_dir/share/vala/vapi -g 
    VALAFLAGS	= ""

    # Set the C compiler.
    CC			= "gcc"

    # Add any additional flags to pass to the C compiler.
    CFLAGS		= "-O -Wall"

    # Add any additional flags to pass to the compiler during
    # the linking phase.
    OFLAGS		= ""
    
    # Get pkg-config cflags and libs
    PKG_CFLAGS 	= `PKG_CONFIG_PATH=#{PKGCONFIGPATH}; pkg-config --cflags #{PKGS}`.strip
    PKG_LIBS 	= `PKG_CONFIG_PATH=#{PKGCONFIGPATH}; pkg-config --libs   #{PKGS}`.strip

    public
    
    def vapi(vapi_file)
        vala_file = @pfs.vala_file_of(vapi_file)
        
        #valac doesnt refresh a vapi file if it's content was not changed!
        puts "POSSIBLEGEN vapi    #{vapi_file}  from: #{vala_file}"
        
        sh "#{VALAC} --fast-vapi=#{vapi_file} #{vala_file}"
    end #vapi
    
    def dep(dep_file)
        #the dep files are created as a side effect during c file creation
        c(@pfs.c_file_of(dep_file))        
    end #dep
    
    def c(c_file)
        vala_file = @pfs.vala_file_of(c_file)
        dep_file  = @pfs.dep_file_of(c_file)
        
        #include the interface (vapi) of all project files except of mine
        use_fast_vapi = ""
        @pfs.vapi_files_of(dep_file).each {|vpf| use_fast_vapi << "--use-fast-vapi=#{vpf} "}
        
        pkg = ""
        PKGS.split.each {|p| pkg << "--pkg=#{p} "}
        
        #WARNING: the output file is very tricky to determine
        #a simple -o t.name will be ignored
        #a base and a destination directory must be given explicitly!
        determine_output_file = "-b #{@pfs.dir_of(vala_file)} -d #{@pfs.dir_of_generated_files}"
        
        #as side effect we creates the dependecy file of the generated c file
        #valac doesnt refresh a c file if no contentchange was made but the dep file will be allways renewed
        dependency = "--deps=#{$pfs.dep_file_of(c_file)}"
        
        puts "POSSIBLEGEN c    #{c_file} GEN dep #{dep_file}      from all needed vapi and vala: #{vala_file}"
        sh "PKG_CONFIG_PATH=#{PKGCONFIGPATH}; #{VALAC} #{pkg} #{dependency} -C #{vala_file} #{determine_output_file} #{VALAFLAGS} #{use_fast_vapi}"
    end #c
    
    def o(o_file)
        c_file = o_file.pathmap("%X.c")
        
        puts "GEN o    #{o_file}  from: #{c_file}"
	
        sh "#{CC} #{CFLAGS} #{PKG_CFLAGS} -c #{c_file} -o #{o_file}"
    end #o

    def link(file_name, o_files)
        puts "GEN #{file_name}"
        sh "#{CC} -o #{file_name} #{OFLAGS} #{o_files} #{PKG_LIBS}"
    end #link
    
end #Build

#Turn off the echoing of shell commands
verbose(false)

#knowhow about the file structures and vala build steps
#######################################################

$pfs   = ProjectFileStructure.new()
$build = Build.new($pfs)

#main tasks
###########

task :default => $pfs.production_executable
task :test    => $pfs.test_executable do |t|
    puts "---running test----"
    puts `#{$pfs.test_executable}`
end

desc "removing generated directories"
task :clean do
    $pfs.all_generated_dirs.each {|d| sh "rm -rf #{d}"}
end

desc "linking $pfs.production_executable"
file $pfs.production_executable => $pfs.all_o_files_for_production do |t|
    $build.link(t.name, $pfs.all_o_files_for_production)
end

desc "linking $pfs.test_executable"
file $pfs.test_executable => $pfs.all_o_files_for_test do |t|
    $build.link(t.name, $pfs.all_o_files_for_test)
end


#build dependencies
###################

desc "creating the vapi files"
task :vapi_files => $pfs.all_vapi_files
$pfs.all_vapi_files.each do |vapi_file|
    file vapi_file  => $pfs.vala_file_of(vapi_file)
end

#no explicit c file creation: 
#c and dep files are generated in the same build step with different refreshing behaviour:
#a c file is refreshed only if it's content changed
#a dep file is refreshed allways
desc "creating the dep files"
task :dep_files => :vapi_files
task :dep_files => $pfs.all_dep_files
$pfs.all_dep_files.each do |dep_file|
    #define our build depencencies
    file dep_file => $pfs.vala_file_of(dep_file)
    file dep_file => $pfs.vapi_files_of(dep_file)
    
    #propagate the change of our interface
    #WHY IS THIS NEEDED? because the execution path goes from the final target to its dependencies
    #and this is the only way to let check the dependency of our vapi file
    file dep_file => $pfs.vapi_file_of(dep_file)
end

desc "creating the o files"
task :o_files => :dep_files
task :o_files => $pfs.all_o_files
$pfs.all_o_files.each do |o_file|
    file o_file => $pfs.dep_file_of(o_file)
end

#rules to build a certain kind of file
######################################

rule '.vapi' do |t|
    $build.vapi(t.name)
end

rule '.dep' do |t|
    $build.dep(t.name)
end

rule '.c' do |t|
    $build.c(t.name)
end

rule '.o' do |t|
    $build.o(t.name)
end


