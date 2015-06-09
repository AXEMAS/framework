import os
from setuptools import setup

version = "0.0.4"

here = os.path.abspath(os.path.dirname(__file__))

install_requires = [
    "gearbox>=0.0.6"
]

try:
    README = open(os.path.join(here, 'README.rst')).read()
except IOError:
    README = ''

setup(name='axemas',
      version=version,
      url='',
      keywords="axemas quickstart",
      author='AXANT',
      author_email='tech@axant.it',
      license='MIT',
      install_requires=install_requires,
      packages=['axemas',],
      long_description=README,
      description='Quickstart script for gearbox that setups a new mobile project using AXEMAS.',
      zip_safe=False,
      classifiers=[
          "Framework :: Setuptools Plugin"
      ],
      entry_points={
          'gearbox.commands': [
              'axemas-setup = axemas.command:MakeBaseProject',
          ]
      })
