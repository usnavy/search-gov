SearchgovUrl.destroy_all
I14yDrawer.find_by_handle('searchgov').destroy
I14yDrawer.create!(handle: 'searchgov')
