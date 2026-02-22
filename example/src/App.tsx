import * as React from 'react';
import { launchImageLibrary } from 'react-native-image-picker';
import {
  StyleSheet,
  ScrollView,
  Image,
  SafeAreaView,
  Text,
  View,
  TouchableOpacity,
  Switch,
  TextInput,
  Modal,
} from 'react-native';
import {
  scanDocuments,
  processDocuments,
  Filter,
  Format,
  type ScanResult,
  type ScanMetadata,
  type ScanOptions,
  type ProcessOptions,
  type FilterType,
  type FormatType,
} from '@hoshomoh/react-native-document-scanner';

/* Helper Components */
const OptionRow = ({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) => (
  <View style={styles.optionRow}>
    <Text style={styles.optionLabel}>{label}</Text>
    {children}
  </View>
);

/**
 * Radio group using native Switch components.
 * Only one option can be selected at a time.
 */
function SwitchGroup<T extends string>({
  options,
  selected,
  onSelect,
  labels,
}: {
  options: T[];
  selected: T;
  onSelect: (v: T) => void;
  labels?: Record<T, string>;
}) {
  return (
    <View style={styles.radioGroup}>
      {options.map((option) => (
        <View key={option} style={styles.radioRow}>
          <Text style={styles.radioLabel}>{labels?.[option] ?? option}</Text>
          <Switch
            value={selected === option}
            onValueChange={(v) => {
              if (v) {
                onSelect(option);
              }
            }}
          />
        </View>
      ))}
    </View>
  );
}

const ENGINE_LABELS: Record<string, string> = {
  RecognizeDocumentsRequest: 'RecognizeDocuments (iOS 26+)',
  VNRecognizeTextRequest: 'VNRecognizeText',
  MLKit: 'ML Kit',
  none: 'None',
};

const MetadataCard = ({ metadata }: { metadata: ScanMetadata }) => (
  <View style={styles.metadataCard}>
    <Text style={styles.metadataCardTitle}>Scan Metadata</Text>
    <View style={styles.metadataRow}>
      <Text style={styles.metadataKey}>Platform</Text>
      <Text style={styles.metadataValue}>{metadata.platform}</Text>
    </View>
    <View style={styles.metadataRow}>
      <Text style={styles.metadataKey}>OCR Engine</Text>
      <Text style={styles.metadataValue}>
        {ENGINE_LABELS[metadata.ocrEngine] ?? metadata.ocrEngine}
      </Text>
    </View>
    <View style={styles.metadataRow}>
      <Text style={styles.metadataKey}>Text Version</Text>
      <Text style={styles.metadataValue}>V{metadata.textVersion}</Text>
    </View>
    <View style={[styles.metadataRow, styles.metadataRowLast]}>
      <Text style={styles.metadataKey}>Filter</Text>
      <Text style={styles.metadataValue}>{metadata.filter}</Text>
    </View>
  </View>
);

export default function App() {
  const [results, setResults] = React.useState<ScanResult[]>([]);
  const [isSettingsVisible, setIsSettingsVisible] = React.useState(false);

  /* Options State */
  const [maxPageCount, setMaxPageCount] = React.useState('5');
  const [quality, setQuality] = React.useState('0.8');
  const [format, setFormat] = React.useState<FormatType>('jpg');
  const [filter, setFilter] = React.useState<FilterType>('color');
  const [includeBase64, setIncludeBase64] = React.useState(false);
  const [includeText, setIncludeText] = React.useState(true);
  const [textVersion, setTextVersion] = React.useState('2');

  const handleScan = async () => {
    const options: ScanOptions = {
      maxPageCount: parseInt(maxPageCount, 10) || 5,
      quality: parseFloat(quality) || 0.8,
      format,
      filter,
      includeBase64,
      includeText,
      textVersion: parseInt(textVersion, 10),
    };

    try {
      const scannedResults = await scanDocuments(options);
      setResults(scannedResults);
    } catch (e: any) {
      console.error('Scan failed:', e);
    }
  };

  const handleSelectImages = async () => {
    try {
      const result = await launchImageLibrary({
        mediaType: 'photo',
        selectionLimit: 0,
        includeBase64: false,
      });

      if (result.didCancel || !result.assets) {
        return;
      }

      const uris = result.assets
        .map((asset) => asset.uri)
        .filter((uri): uri is string => !!uri);

      await processImages(uris);
    } catch (e) {
      console.error('Failed to select images:', e);
    }
  };

  const processImages = async (uris: string[]) => {
    const options: ProcessOptions = {
      images: uris,
      quality: parseFloat(quality) || 0.8,
      format,
      filter,
      includeBase64,
      includeText,
      textVersion: parseInt(textVersion, 10),
    };

    try {
      const processedResults = await processDocuments(options);
      setResults(processedResults);
    } catch (e: any) {
      console.error('Processing failed:', e);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Doc Scanner</Text>
        <TouchableOpacity
          style={styles.settingsIconButton}
          onPress={() => setIsSettingsVisible(true)}
        >
          <Text style={styles.settingsIcon}>⚙️</Text>
        </TouchableOpacity>
      </View>

      {/* Main Controls - Side by Side */}
      <View style={styles.mainControls}>
        <TouchableOpacity style={styles.actionButton} onPress={handleScan}>
          <Text style={styles.actionButtonText}>📷 Scan</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.actionButton, styles.secondaryButton]}
          onPress={handleSelectImages}
        >
          <Text style={styles.actionButtonText}>🖼️ Gallery</Text>
        </TouchableOpacity>
      </View>

      {/* Settings Modal */}
      <Modal
        visible={isSettingsVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setIsSettingsVisible(false)}
      >
        <SafeAreaView style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Scan Settings</Text>
            <TouchableOpacity onPress={() => setIsSettingsVisible(false)}>
              <Text style={styles.closeButton}>Done</Text>
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.settingsScroll}>
            <View style={styles.settingsContent}>
              <OptionRow label="Max Pages">
                <TextInput
                  style={styles.textInput}
                  value={maxPageCount}
                  onChangeText={setMaxPageCount}
                  keyboardType="number-pad"
                  placeholder="5"
                />
              </OptionRow>

              <OptionRow label="Quality">
                <TextInput
                  style={styles.textInput}
                  value={quality}
                  onChangeText={setQuality}
                  keyboardType="decimal-pad"
                  placeholder="0.8"
                />
              </OptionRow>

              <View style={styles.radioSection}>
                <Text style={styles.radioSectionTitle}>Format</Text>
                <SwitchGroup
                  options={[Format.JPG, Format.PNG]}
                  selected={format}
                  onSelect={setFormat}
                  labels={{
                    [Format.JPG]: 'JPEG (Smaller)',
                    [Format.PNG]: 'PNG (Lossless)',
                  }}
                />
              </View>

              <View style={styles.radioSection}>
                <Text style={styles.radioSectionTitle}>Filter</Text>
                <SwitchGroup
                  options={[
                    Filter.COLOR,
                    Filter.GRAYSCALE,
                    Filter.MONOCHROME,
                    Filter.DENOISE,
                    Filter.SHARPEN,
                    Filter.OCR_OPTIMIZED,
                  ]}
                  selected={filter}
                  onSelect={setFilter}
                  labels={{
                    [Filter.COLOR]: 'Color (Original)',
                    [Filter.GRAYSCALE]: 'Grayscale',
                    [Filter.MONOCHROME]: 'Monochrome (B&W)',
                    [Filter.DENOISE]: 'Denoise',
                    [Filter.SHARPEN]: 'Sharpen',
                    [Filter.OCR_OPTIMIZED]: 'OCR Optimized ⭐',
                  }}
                />
              </View>

              <OptionRow label="Include Base64">
                <Switch
                  value={includeBase64}
                  onValueChange={setIncludeBase64}
                />
              </OptionRow>

              <OptionRow label="Include Text (OCR)">
                <Switch value={includeText} onValueChange={setIncludeText} />
              </OptionRow>

              <View style={styles.radioSection}>
                <Text style={styles.radioSectionTitle}>OCR Version</Text>
                <SwitchGroup
                  options={['1', '2']}
                  selected={textVersion}
                  onSelect={setTextVersion}
                  labels={{
                    '1': 'V1 (Raw)',
                    '2': 'V2 (Heuristic)',
                  }}
                />
              </View>
            </View>
          </ScrollView>
        </SafeAreaView>
      </Modal>

      {/* Results */}
      <ScrollView contentContainerStyle={styles.scrollContent}>
        {results.length === 0 && (
          <Text style={styles.placeholder}>
            No scans yet. tap Scan or Gallery above.
          </Text>
        )}
        {results.map((result, index) => (
          <View key={index} style={styles.pageContainer}>
            <Text style={styles.pageTitle}>Page {index + 1}</Text>
            {result.uri && (
              <Image
                source={{ uri: result.uri }}
                style={styles.image}
                resizeMode="contain"
              />
            )}
            {result.metadata && <MetadataCard metadata={result.metadata} />}
            {result.text && (
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>Extracted Text:</Text>
                <View style={styles.textWrapper}>
                  <Text selectable style={styles.textContent}>
                    {result.text}
                  </Text>
                </View>
              </View>
            )}
            {result.blocks && (
              <View style={styles.sectionContainer}>
                <Text style={styles.sectionTitle}>
                  OCR Blocks ({result.blocks.length}):
                </Text>
                <View style={styles.codeWrapper}>
                  <Text selectable style={styles.codeContent}>
                    {JSON.stringify(result.blocks, null, 2)}
                  </Text>
                </View>
              </View>
            )}
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  header: {
    paddingHorizontal: 20,
    paddingVertical: 15,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#f0f0f0',
  },
  headerTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#1a1a1a',
  },
  settingsIconButton: {
    padding: 8,
    backgroundColor: '#f5f5f5',
    borderRadius: 20,
  },
  settingsIcon: {
    fontSize: 20,
  },
  mainControls: {
    flexDirection: 'row',
    padding: 16,
    gap: 12,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#007AFF',
    paddingVertical: 15,
    borderRadius: 12,
    alignItems: 'center',
    shadowColor: '#007AFF',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.2,
    shadowRadius: 8,
    elevation: 4,
  },
  secondaryButton: {
    backgroundColor: '#5856D6',
    shadowColor: '#5856D6',
  },
  actionButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#fff',
  },
  modalHeader: {
    padding: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  closeButton: {
    fontSize: 17,
    color: '#007AFF',
    fontWeight: '600',
  },
  settingsScroll: {
    flex: 1,
  },
  settingsContent: {
    padding: 20,
  },
  optionRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
  },
  optionLabel: {
    fontSize: 16,
    color: '#333',
    fontWeight: '500',
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    width: 70,
    textAlign: 'center',
    fontSize: 15,
    backgroundColor: '#fafafa',
  },
  radioGroup: {
    width: '100%',
  },
  radioRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 0.5,
    borderBottomColor: '#f0f0f0',
  },
  radioLabel: {
    fontSize: 15,
    color: '#444',
    flex: 1,
  },
  radioSection: {
    marginTop: 15,
    marginBottom: 5,
    borderWidth: 1,
    borderColor: '#eee',
    borderRadius: 12,
    padding: 15,
    backgroundColor: '#f9f9f9',
  },
  radioSectionTitle: {
    fontSize: 15,
    fontWeight: '700',
    color: '#1a1a1a',
    marginBottom: 8,
  },
  scrollContent: {
    padding: 16,
    paddingBottom: 40,
  },
  placeholder: {
    fontSize: 15,
    color: '#999',
    textAlign: 'center',
    marginTop: 60,
  },
  pageContainer: {
    width: '100%',
    marginBottom: 30,
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 2,
  },
  pageTitle: {
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 12,
    color: '#1a1a1a',
  },
  image: {
    width: '100%',
    height: 350,
    borderRadius: 12,
    backgroundColor: '#f8f8f8',
  },
  sectionContainer: {
    marginTop: 20,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '600',
    marginBottom: 8,
    color: '#444',
  },
  textWrapper: {
    backgroundColor: '#f8f8f8',
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#eee',
  },
  textContent: {
    fontSize: 13,
    lineHeight: 18,
    color: '#222',
  },
  codeWrapper: {
    backgroundColor: '#1a1a1a',
    padding: 12,
    borderRadius: 10,
  },
  codeContent: {
    fontSize: 11,
    color: '#4ade80',
    fontFamily: 'Courier',
  },
  metadataCard: {
    marginTop: 14,
    backgroundColor: '#f0f7ff',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#c9e0ff',
    overflow: 'hidden',
  },
  metadataCardTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0055cc',
    paddingHorizontal: 12,
    paddingTop: 10,
    paddingBottom: 6,
    borderBottomWidth: 1,
    borderBottomColor: '#c9e0ff',
  },
  metadataRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderBottomWidth: 0.5,
    borderBottomColor: '#d8eaff',
  },
  metadataRowLast: {
    borderBottomWidth: 0,
  },
  metadataKey: {
    fontSize: 12,
    color: '#555',
    fontWeight: '500',
  },
  metadataValue: {
    fontSize: 12,
    color: '#1a1a1a',
    fontWeight: '600',
    textAlign: 'right',
    flexShrink: 1,
    marginLeft: 8,
  },
});
