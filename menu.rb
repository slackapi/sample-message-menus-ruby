class Menu
  @@items =  [
    {
      id: 'cappuccino',
      name: 'Cappuccino',
      options: ['milk'],
    },
    {
      id: 'americano',
      name: 'Americano',
      options: ['strength'],
    },
    {
      id: 'gibraltar',
      name: 'Gibraltar',
      options: ['milk'],
    },
    {
      id: 'latte',
      name: 'Latte',
      options: ['milk'],
    },
    {
      id: 'lavlatte',
      name: 'Lavendar Latte',
      options: ['milk'],
    },
    {
      id: 'mintlatte',
      name: 'Mint Latte',
      options: ['milk'],
    },
    {
      id: 'espresso',
      name: 'Espresso',
      options: ['strength'],
    },
    {
      id: 'espressomach',
      name: 'Espresso Macchiato',
      options: ['milk'],
    },
    {
      id: 'mocha',
      name: 'Mocha',
      options: ['milk'],
    },
    {
      id: 'tea',
      name: 'Hot Tea',
      options: ['milk'],
    }
  ]

  @@options = [
    {
      id: 'strength',
      choices: [
        {
          id: 'single',
          name: 'Single',
        },
        {
          id: 'double',
          name: 'Double',
        },
        {
          id: 'triple',
          name: 'Triple',
        },
        {
          id: 'quad',
          name: 'Quad',
        },
      ],
    },
    {
      id: 'milk',
      choices: [
        {
          id: 'whole',
          name: 'Whole',
        },
        {
          id: 'lowfat',
          name: 'Low fat',
        },
        {
          id: 'almond',
          name: 'Almond',
        },
        {
          id: 'soy',
          name: 'Soy',
        },
      ],
    }
  ]

  def self.items
    @@items
  end

  def self.options
    @@options
  end

  def self.list_of_types
    self.items.map { |i| ({ text: i[:name], value: i[:id] })}
  end

  def self.list_of_choices_for_option(option_id)
    choices = self.options.find {|o| o[:id] == option_id}[:choices]
    return choices.map { |c| ({ text: c[:name], value: c[:id]})}
  end

  def self.choice_name_for_id(option_id, choice_id)
    option = self.options.find {|o| o[:id] == option_id}
    if !option.nil?
      choice = option[:choices].find {|c| c[:id] == choice_id}
      return choice[:name]
    end
    return false
  end
  
end
