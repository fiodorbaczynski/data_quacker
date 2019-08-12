Mox.defmock(DataQuacker.MockFileManager, for: DataQuacker.FileManager)

Application.put_env(:data_quacker, :file_manager, DataQuacker.MockFileManager)

ExUnit.start()
