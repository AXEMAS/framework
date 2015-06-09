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
        opts.package_loc = None
        opts.package_company = None
        opts.package_name = None

        if opts.package_name is None:
            opts.package_name = self.CLEAN_PACKAGE_NAME_RE.sub('', opts.project.lower())

        if opts.global_package is None:
            opts.global_package = "com.company.{}".format(opts.package_name)
            split_package = opts.global_package.split('.')
        elif self.check_global_package(opts.global_package):
            split_package = opts.global_package.split('.')
        else:
            print("Package name does nor respect the required format: 'com.company.package'")
            return None

        opts.package_loc = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[0].lower())
        opts.package_company = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[1].lower())
        opts.package_name = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[2].lower())

        if opts.output_dir is None:
            opts.output_dir = opts.project.lower()

        opts.zip_safe = False
        opts.version = '0.0.1'

        self.run_template(opts.output_dir, opts)


        # Project renaming
        print("Renaming project")
        # move Android tests directory
        if opts.package_name != "application":
            os.system(
                "mv ./{output_dir}/android/app/src/androidTest/java/it/axant/application ./{output_dir}/android/app/src/androidTest/java/it/axant/{package}".format(
                    output_dir=opts.output_dir, package=opts.package_name))
        if opts.package_company != "axant":
            os.system(
                "mv ./{output_dir}/android/app/src/androidTest/java/it/axant ./{output_dir}/android/app/src/androidTest/java/it/{company}".format(
                    output_dir=opts.output_dir, package=opts.package_name, company=opts.package_company))
        if opts.package_loc != "it":
            os.system(
                "mv ./{output_dir}/android/app/src/androidTest/java/it ./{output_dir}/android/app/src/androidTest/java/{loc}".format(
                    output_dir=opts.output_dir, package=opts.package_name, loc=opts.package_loc))


        # move Android application package
        if opts.package_name != "application":
            os.system(
                "mv ./{output_dir}/android/app/src/main/java/it/axant/application ./{output_dir}/android/app/src/main/java/it/axant/{package}".format(
                    output_dir=opts.output_dir, package=opts.package_name))
        if opts.package_company != "axant":
            os.system(
                "mv ./{output_dir}/android/app/src/main/java/it/axant ./{output_dir}/android/app/src/main/java/it/{company}".format(
                    output_dir=opts.output_dir, package=opts.package_name, company=opts.package_company))
        if opts.package_loc != "it":
            os.system(
                "mv ./{output_dir}/android/app/src/main/java/it ./{output_dir}/android/app/src/main/java/{loc}".format(
                    output_dir=opts.output_dir, package=opts.package_name, loc=opts.package_loc))


        # rename iOS project
        os.system(
            "mv ./{output_dir}/ios/axemas.xcodeproj ./{output_dir}/ios/{project}.xcodeproj".format(
                output_dir=opts.output_dir, package=opts.package_name, project=opts.project))
        os.system(
            "mv ./{output_dir}/ios/axemas/axemas-Info.plist ./{output_dir}/ios/axemas/{project}-Info.plist".format(
                output_dir=opts.output_dir, package=opts.package_name, project=opts.project))
        os.system(
            "mv ./{output_dir}/ios/axemas/axemas-Prefix.pch ./{output_dir}/ios/axemas/{project}-Prefix.pch".format(
                output_dir=opts.output_dir, package=opts.package_name, project=opts.project))


        # run commands after the template finished processing

        print("Running chmod +x on copy-www-build-step.sh")
        os.system("chmod +x ./{output_dir}/ios/scripts/copy-www-build-step.sh".format(output_dir=opts.output_dir))


        # clone && copy release distribution
        os.system("rm -Rf {dir}".format(dir=REPOSITORY_CLONE_DIR))

        print("Clonging repository {repo} to {dir}".format(repo=GIT_REMOTE_REPOSITORY, dir=REPOSITORY_CLONE_DIR))
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
