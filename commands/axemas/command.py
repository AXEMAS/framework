from __future__ import print_function
import os
import re

from gearbox.command import TemplateCommand

REPOSITORY_CLONE_DIR = "./temp_repo"
GIT_REMOTE_REPOSITORY = "https://github.com/AXEMAS/releases.git"

class MakeBaseProject(TemplateCommand):
    CLEAN_PACKAGE_NAME_RE = re.compile('[^a-zA-Z0-9_]')

    def get_description(self):
        return 'Creates the structure for a new Axemas project'

    def check_global_package(self, package):
        if package.count('.') != 2:
            return False
        return True


    def get_parser(self, prog_name):
        parser = super(MakeBaseProject, self).get_parser(prog_name)

        parser.add_argument('-n', '--name', dest='project',
                            metavar='NAME', required=True,
                            help="Project Name")

        parser.add_argument('-p', '--package', dest='global_package',
                            metavar='full package name',
                            help="Input the project like com.company.project")

        parser.add_argument('-o', '--output-dir', dest='output_dir',
                            metavar='OUTPUT_DIR',
                            help="Destination directory (by default the project name)")

        return parser

    def take_action(self, opts):
        opts.version = '0.0.1'

        opts.project_id = '_'.join(opts.project.split()).lower()
        opts.package_name = self.CLEAN_PACKAGE_NAME_RE.sub('', opts.project_id)

        if opts.global_package:
            opts.global_package = opts.global_package.lower()
        else:
            opts.global_package = "com.company.{}".format(opts.package_name)

        if self.check_global_package(opts.global_package):
            split_package = opts.global_package.split('.')
        else:
            print("Package name does not respect the required format: 'com.company.package'")
            return False

        opts.package_loc = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[0])
        opts.package_company = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[1])
        opts.package_name = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[2])

        if opts.output_dir is None:
            opts.output_dir = opts.project_id

        self.run_template(opts.output_dir, opts)

        print("Making Gradle Wrapper Runnable")
        os.system("chmod +x ./{output_dir}/android/gradlew".format(output_dir=opts.output_dir))

        print("Making iOS Scripts Runnable")
        os.system("chmod +x ./{output_dir}/ios/scripts/copy-www-build-step.sh".format(output_dir=opts.output_dir))

        # clone && copy release distribution
        print("Cloning repository {repo} to {dir}".format(repo=GIT_REMOTE_REPOSITORY, dir=REPOSITORY_CLONE_DIR))
        os.system("rm -Rf {dir}".format(dir=REPOSITORY_CLONE_DIR))
        os.system("git clone {repo} {dir}".format(repo=GIT_REMOTE_REPOSITORY, dir=REPOSITORY_CLONE_DIR))

        os.system("cp -R {temp_repo}/ios/release ./{output_dir}/ios/axemas".format(
            temp_repo=REPOSITORY_CLONE_DIR, output_dir=opts.output_dir))
        os.system("cp -R {temp_repo}/android/axemas.aar ./{output_dir}/android/app/libs".format(
            temp_repo=REPOSITORY_CLONE_DIR, output_dir=opts.output_dir))
        os.system("cp -R {temp_repo}/html/ ./{output_dir}/axemas-js/".format(
            temp_repo=REPOSITORY_CLONE_DIR, output_dir=opts.output_dir))

        os.system("rm -Rf {dir}".format(dir=REPOSITORY_CLONE_DIR))

        # create symlink to library files
        # www
        os.chdir("./{output_dir}/www".format(output_dir=opts.output_dir))
        os.system("ln -s ../axemas-js/ axemas".format(output_dir=opts.output_dir))
        # iOS
        os.chdir("../ios")
        os.system("ln -s ../www/ www".format(output_dir=opts.output_dir))
        # Android
        os.chdir("../android/app/src/main/assets")
        os.system("ln -s ../../../../../www/ www".format(output_dir=opts.output_dir))

        print("Axemas project structure created.")
