from __future__ import print_function

import os
import re
import stat
import tempfile
import shutil

from gearbox.command import TemplateCommand

GIT_REMOTE_REPOSITORY = "https://github.com/AXEMAS/releases.git"


class MakeBaseProject(TemplateCommand):
    CLEAN_PACKAGE_NAME_RE = re.compile('[^a-zA-Z0-9_]')

    def get_description(self):
        return 'Creates the structure for a new Axemas project'

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

        if self._check_global_package(opts.global_package):
            split_package = opts.global_package.split('.')
        else:
            print("Package name does not respect the required format: 'com.company.package'")
            return False

        opts.package_loc = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[0])
        opts.package_company = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[1])
        opts.package_name = self.CLEAN_PACKAGE_NAME_RE.sub('', split_package[2])

        if opts.output_dir is None:
            opts.output_dir = opts.project_id

        opts.output_dir = os.path.abspath(opts.output_dir)
        self.run_template(opts.output_dir, opts)

        print("Making Gradle Wrapper Runnable")
        self._make_exec(os.path.join(opts.output_dir, "android", "gradlew"))

        print("Making iOS Scripts Runnable")
        self._make_exec(os.path.join(opts.output_dir, "ios", "scripts", "copy-www-build-step.sh"))

        # clone && copy release distribution
        with TemporaryDirectory('axemas_repo') as axemas_temporary:
            self._git_clone(GIT_REMOTE_REPOSITORY, axemas_temporary)
            self._copy(os.path.join(axemas_temporary, 'ios', 'release'),
                       os.path.join(opts.output_dir, 'ios', 'axemas'))
            self._copy(os.path.join(axemas_temporary, 'android', 'axemas.aar'),
                       os.path.join(opts.output_dir, 'android', 'app', 'libs'))
            self._copy(os.path.join(axemas_temporary, 'html'),
                       os.path.join(opts.output_dir, 'axemas-js'))

        # create symlink to WWW directory, so it's shared between iOS and Android projects.
        self._lns(os.path.join('..', 'axemas-js'),
                  os.path.join(opts.output_dir, 'www', 'axemas'))
        self._lns(os.path.join('..', 'www'),
                  os.path.join(opts.output_dir, 'ios', 'www'))
        self._lns(os.path.join('..', '..', '..', '..', '..', 'www'),
                  os.path.join(opts.output_dir, 'android', 'app', 'src', 'main', 'assets', 'www'))

        print("AXEMAS project {} created!".format(opts.project))

    def _check_global_package(self, package):
        if package.count('.') != 2:
            return False
        return True

    def _make_exec(self, path):
        print('Marking {} runnable'.format(path))
        st = os.stat(path)
        os.chmod(path, st.st_mode | stat.S_IEXEC)

    def _copy(self, path1, path2):
        print('Copying {} -> {}'.format(path1, path2))
        if os.path.isdir(path1):
            shutil.copytree(path1, path2)
        else:
            shutil.copy(path1, path2)

    def _git_clone(self, repo, dest):
        # This should be upgraded to avoid using os.system
        print("Cloning repository {repo} to {dest}".format(repo=repo, dest=dest))
        os.system("git clone --depth 1 {repo} {dest}".format(repo=repo, dest=dest))

    def _lns(self, orig, dest):
        print("Linking {} -> {}".format(orig, dest))
        os.symlink(orig, dest)


class TemporaryDirectory(object):
    def __init__(self, name):
        self._name = name
        self._basepath = None

    def __enter__(self):
        self._basepath = tempfile.mkdtemp()
        return os.path.join(self._basepath, self._name)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self._basepath is not None:
            shutil.rmtree(self._basepath)
