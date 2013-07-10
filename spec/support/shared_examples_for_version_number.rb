shared_examples_for "a version" do |version_array|
  it{expect(subject.instance_variable_get('@version')).to(have_key('major'))}
  it{expect(subject.instance_variable_get('@version')).to(have_key('minor'))}
  it{expect(subject.instance_variable_get('@version')).to(have_key('patch'))}
  it{expect(subject.instance_variable_get('@version')).to(have_key('pre'))}

  it{
    expect(
      subject.instance_variable_get('@version')
    ).to(eq(
      {
        'major' => version_array[0],
        'minor' => version_array[1],
        'patch' => version_array[2],
        'pre' => version_array[3]
      }
    ) )
  }
end
